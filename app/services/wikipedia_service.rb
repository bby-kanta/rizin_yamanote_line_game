require 'net/http'
require 'uri'
require 'json'
require 'cgi'

class WikipediaService
  BASE_URL = 'https://ja.wikipedia.org/w/api.php'
  
  class APIError < StandardError; end

  def self.fetch_fighter_content(fighter_name)
    new(fighter_name).fetch_content_only
  end
  
  def self.fetch_fighter_records(fighter_name)
    new(fighter_name).fetch_records_only
  end
  
  def self.fetch_fighter_basic_info(fighter_name)
    new(fighter_name).fetch_basic_info_only
  end
  
  def self.fetch_fighter_info(fighter_name)
    new(fighter_name).fetch_info
  end

  def initialize(fighter_name)
    @fighter_name = fighter_name
  end
  
  def fetch_content_only
    # テキストコンテンツのみを取得（戦績は含まない）
    page_title = search_page || @fighter_name
    content_data = fetch_page_content(page_title)

    return nil unless content_data

    {
      content: clean_text_content(content_data[:text]),
      sections: extract_sections(content_data[:text])
    }
  rescue => e
    Rails.logger.error "Wikipedia content fetch error for #{@fighter_name}: #{e.message}"
    nil
  end
  
  def fetch_records_only
    # 戦績データのみを取得
    page_title = search_page || @fighter_name
    html_content = fetch_html_content(page_title)
    
    return [] unless html_content
    
    parse_fight_records(html_content)
  rescue => e
    Rails.logger.error "Wikipedia records fetch error for #{@fighter_name}: #{e.message}"
    []
  end
  
  def fetch_basic_info_only
    # 基本情報（infobox）のみを取得
    page_title = search_page || @fighter_name
    html_content = fetch_html_content(page_title)
    
    return [] unless html_content
    
    parse_basic_info(html_content)
  rescue => e
    Rails.logger.error "Wikipedia basic info fetch error for #{@fighter_name}: #{e.message}"
    []
  end

  def fetch_info
    # 従来通り全データを取得（後方互換性のため）
    page_title = search_page || @fighter_name
    content = fetch_page_content(page_title)
    clean_content(content)
  rescue => e
    Rails.logger.error "Wikipedia fetch error for #{@fighter_name}: #{e.message}"
    nil
  end

  private

  def search_page
    params = {
      action: 'query',
      list: 'search',
      srsearch: @fighter_name,
      format: 'json',
      utf8: 1,
      srlimit: 1
    }
    
    response = make_request(params)
    result = response.dig('query', 'search', 0, 'title')
    
    Rails.logger.info "Wikipedia search result for #{@fighter_name}: #{result}"
    result
  end

  def fetch_page_content(page_title)
    # HTMLコンテンツも取得して戦績テーブルを解析
    html_content = fetch_html_content(page_title)
    
    # プレーンテキストも取得
    params = {
      action: 'query',
      prop: 'extracts',
      titles: page_title,
      format: 'json',
      utf8: 1,
      explaintext: 1,  # プレーンテキストで取得
      exsectionformat: 'plain'
    }
    
    response = make_request(params)
    pages = response.dig('query', 'pages')
    
    return nil if pages.nil?
    
    # ページIDは動的なので、最初のページを取得
    page = pages.values.first
    extract = page['extract']
    
    Rails.logger.info "Wikipedia content fetched for #{page_title}: #{extract&.length} characters"
    
    # 戦績テーブルを解析
    fight_records = parse_fight_records(html_content) if html_content
    
    { text: extract, fight_records: fight_records }
  end
  
  def fetch_html_content(page_title)
    params = {
      action: 'parse',
      page: page_title,
      format: 'json',
      utf8: 1,
      prop: 'text'
    }
    
    response = make_request(params)
    html = response.dig('parse', 'text', '*')
    
    Rails.logger.info "Wikipedia HTML fetched for #{page_title}"
    html
  rescue => e
    Rails.logger.error "Failed to fetch HTML: #{e.message}"
    nil
  end
  
  def parse_fight_records(html)
    return [] unless html
    
    require 'nokogiri'
    doc = Nokogiri::HTML(html)
    
    records = []
    
    # テーブル形式の戦績を探す
    tables = doc.css('table')
    
    tables.each do |table|
      table_text = table.text
      # 戦績テーブルの特徴的なキーワードで判定
      if table_text.include?('勝敗') && table_text.include?('対戦相手') ||
         table_text.include?('判定') && table_text.include?('vs')
        
        rows = table.css('tr')
        
        # ヘッダー行をスキップ
        rows.drop(1).each do |row|
          cols = row.css('td')
          next if cols.length < 3
          
          record = parse_fight_record_row(cols)
          records << record if record[:opponent].present?
        end
        break # 最初の戦績テーブルのみ処理
      end
    end
    
    # テーブルが見つからない場合は本文から戦績を抽出
    if records.empty?
      records = extract_fights_from_text(doc.text)
    end
    
    Rails.logger.info "Parsed #{records.length} fight records"
    records
  rescue => e
    Rails.logger.error "Failed to parse fight records: #{e.message}"
    []
  end
  
  def parse_fight_record_row(cols)
    # カラム数によって戦績テーブルの形式を判定
    {
      result: cols[0]&.text&.strip,
      opponent: cols[1]&.text&.strip,
      event: cols[2]&.text&.strip,
      method: cols[3]&.text&.strip,
      round: cols[4]&.text&.strip,
      time: cols[5]&.text&.strip,
      date: cols[6]&.text&.strip
    }
  end
  
  def extract_fights_from_text(text)
    records = []
    
    # より詳細なパターンで戦績を抽出
    # パターン1: "YYYY年MM月DD日、イベント名でXXXと対戦し、結果"
    fight_pattern1 = /(\d{4}年\d{1,2}月\d{1,2}日)、([^でと]+)で([^と]+)と対戦し、(.+?)。/
    
    matches = text.scan(fight_pattern1)
    
    matches.each do |match|
      date_str, event, opponent, result_str = match
      
      # 結果を判定
      result = case result_str
               when /勝ち|勝利/ then '○'
               when /負け|敗北/ then '×'
               when /判定.*勝/ then '○'
               when /判定.*負/ then '×'
               when /TKO勝/ then '○'
               when /TKO負/ then '×'
               else
                 result_str.include?('3-0') && result_str.include?('判定') ? '○' : 
                 result_str.include?('0-3') && result_str.include?('判定') ? '×' : '?'
               end
      
      # 決着方法を抽出
      method = case result_str
               when /判定/ then (result_str.match(/\d+-\d+/) || [])[0] || '判定'
               when /TKO/ then 'TKO'
               when /一本/ then '一本'
               when /チョーク/ then 'サブミッション'
               when /パウンド/ then 'TKO（パウンド）'
               else result_str[0..20]
               end
      
      # ラウンドと時間を抽出
      round_match = result_str.match(/(\d+)R/)
      time_match = result_str.match(/(\d+:\d+)/)
      
      records << {
        date: date_str,
        opponent: opponent.strip,
        result: result,
        method: method.strip,
        event: event.strip,
        round: round_match ? round_match[1] + 'R' : '',
        time: time_match ? time_match[1] : ''
      }
    end
    
    # 日付順に並び替え（新しい順）
    records.sort_by { |r| r[:date] }.reverse
  end
  
  def parse_basic_info(html)
    return [] unless html
    
    require 'nokogiri'
    doc = Nokogiri::HTML(html)
    
    basic_info_features = []
    
    # infoboxテーブルを探す
    infobox = doc.css('table.infobox').first
    return [] unless infobox
    
    # テーブルの各行を解析
    infobox.css('tr').each do |row|
      th = row.css('th').first
      td = row.css('td').first
      
      next unless th && td
      
      field_name = th.text.strip
      field_value = td.text.strip.gsub(/\s+/, ' ')
      
      next if field_value.empty?
      
      # 項目に応じてカテゴリとレベルを決定
      feature_info = categorize_basic_info(field_name, field_value)
      
      if feature_info
        basic_info_features << {
          category: feature_info[:category],
          level: feature_info[:level],
          feature: feature_info[:feature]
        }
      end
    end
    
    Rails.logger.info "Parsed #{basic_info_features.length} basic info features"
    basic_info_features
  rescue => e
    Rails.logger.error "Failed to parse basic info: #{e.message}"
    []
  end
  
  def categorize_basic_info(field_name, field_value)
    case field_name
    when /通称/
      { category: '通称', level: 1, feature: field_value }
    when /階級/
      { category: '階級', level: 3, feature: field_value }
    when /所属/
      { category: '所属', level: 2, feature: "#{field_value}所属" }
    when /国籍/
      { category: '来歴', level: 2, feature: "#{field_value}国籍" }
    when /出身地/
      { category: '来歴', level: 1, feature: "#{field_value}出身" }
    when /居住/
      { category: '来歴', level: 2, feature: "#{field_value}在住" }
    when /身長/
      { category: 'その他', level: 1, feature: "身長#{field_value}" }
    when /体重/
      { category: 'その他', level: 1, feature: "体重#{field_value}" }
    when /リーチ/
      { category: 'その他', level: 1, feature: "リーチ#{field_value}" }
    when /バックボーン/
      { category: 'ファイトスタイル', level: 2, feature: "#{field_value}がバックボーン" }
    when /テーマ曲/
      { category: 'その他', level: 1, feature: "入場テーマ曲は#{field_value}" }
    when /生年月日/
      # 年齢情報を抽出（例：1986年4月4日（39歳））
      if field_value.match(/（(\d+)歳）/)
        age = $1
        { category: 'その他', level: 1, feature: "#{age}歳" }
      else
        nil
      end
    else
      # 認識できない項目は「その他」カテゴリにする
      { category: 'その他', level: 2, feature: "#{field_name}は#{field_value}" }
    end
  end

  def clean_text_content(text)
    return nil if text.nil?
    
    # 脚注や参照の除去
    cleaned = text.dup
    
    # [1], [2]などの脚注番号を削除
    cleaned.gsub!(/\[\d+\]/, '')
    
    # == 脚注 == セクション以降を削除
    cleaned = cleaned.split(/==\s*(脚注|注釈|出典|参考文献|関連項目|外部リンク)/i).first || cleaned
    
    # 複数の改行を1つに
    cleaned.gsub!(/\n{3,}/, "\n\n")
    
    # 前後の空白を削除
    cleaned.strip!
    
    cleaned
  end

  def clean_content(content)
    return nil if content.nil?
    
    text = content[:text]
    fight_records = content[:fight_records] || []
    
    # 基本情報を抽出（通称、階級、戦績など）
    info = {
      content: clean_text_content(text),
      sections: extract_sections(text),
      fight_records: fight_records
    }
    
    info
  end

  def extract_sections(content)
    sections = {}
    current_section = "基本情報"
    
    content.split("\n").each do |line|
      # セクションヘッダーを検出
      if line =~ /^=+\s*(.+?)\s*=+$/
        current_section = $1.strip
        sections[current_section] = []
      else
        sections[current_section] ||= []
        sections[current_section] << line unless line.strip.empty?
      end
    end
    
    sections
  end

  def make_request(params)
    uri = URI(BASE_URL)
    uri.query = URI.encode_www_form(params)
    
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    
    request = Net::HTTP::Get.new(uri)
    response = http.request(request)
    
    unless response.code == '200'
      raise APIError, "Wikipedia API request failed: #{response.code}"
    end
    
    JSON.parse(response.body)
  end
end
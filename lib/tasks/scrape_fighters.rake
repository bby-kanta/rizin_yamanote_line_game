namespace :fighters do
  desc "Scrape RIZIN fighters from official website"
  task scrape: :environment do
    require 'selenium-webdriver'
    require 'nokogiri'
    require 'romaji'

    puts "Starting RIZIN fighters scraping with Selenium (Firefox)..."

    url = "https://jp.rizinff.com/fighters/mma"
    
    begin
      # 環境変数を設定
      ENV['DISPLAY'] = ':99'
      
      # Seleniumでブラウザを起動（ヘッドレスモード）
      options = Selenium::WebDriver::Firefox::Options.new
      options.add_argument('--headless')
      options.add_argument('--no-sandbox')
      options.add_argument('--disable-dev-shm-usage')
      options.add_argument('--disable-gpu')
      options.add_argument('--disable-extensions')
      options.add_argument('--disable-plugins')
      options.add_argument('--window-size=1920,1080')
      
      # Firefoxのバイナリパスを明示的に設定
      options.binary = '/usr/bin/firefox-esr'
      
      driver = Selenium::WebDriver.for :firefox, options: options
      puts "Firefox browser started successfully"
      
      driver.get(url)
      puts "Page loaded, waiting for JavaScript to render..."
      
      # JavaScript実行完了を待機
      wait = Selenium::WebDriver::Wait.new(timeout: 30)
      wait.until { driver.execute_script("return document.readyState") == "complete" }
      
      # 追加で選手データが読み込まれるまで待機
      sleep 10
      puts "JavaScript rendering completed"
      
      # ページソースを取得してNokogiriで解析
      doc = Nokogiri::HTML(driver.page_source)
      
      # デバッグ情報を出力
      puts "\nPage title: #{doc.title}"
      puts "Total elements: #{doc.css('*').length}"
      puts "Links count: #{doc.css('a').length}"
      fighters_scraped = 0
      fighters_created = 0
      errors = []

      # 選手データを探す（複数のパターンを試行）
      fighter_selectors = [
        '.fighter-card',
        '.fighter-item',
        '.player-card',
        '[data-fighter]',
        'a[href*="/fighter/"]',
        '.fighter',
        '.athlete',
        '.profile-card',
        '.player-profile',
        '.member-card',
        '.fighter-list-item',
        '.athlete-card',
        '[data-player]',
        '[data-athlete]',
        '.card',
        '.item'
      ]

      fighter_elements = nil
      fighter_selectors.each do |selector|
        elements = doc.css(selector)
        if elements.any?
          fighter_elements = elements
          puts "Found #{elements.length} elements with selector: #{selector}"
          break
        end
      end

      # personタグ内のh4要素から選手情報を直接抽出
      person_elements = doc.css('.person')
      if person_elements.any?
        puts "Found #{person_elements.length} person elements"
        
        person_elements.each do |person|
          h4_element = person.css('h4').first
          next unless h4_element
          
          # h4内のテキストを<br>で分割
          h4_html = h4_element.inner_html
          parts = h4_html.split('<br>')
          
          if parts.length >= 2
            japanese_name = Nokogiri::HTML(parts[0]).text.strip
            english_name = Nokogiri::HTML(parts[1]).text.strip
            
            next if japanese_name.empty? || english_name.empty?
            next if japanese_name.match?(/\d/) || english_name.match?(/\d/)
            
            puts "DEBUG: Person element - Japanese: '#{japanese_name}', English: '#{english_name}'"
            
            process_fighter_data(japanese_name, english_name, fighters_created, errors)
            fighters_scraped += 1
          end
        end
      else
        # 通常のスクレイピング
        fighter_elements.each do |element|
          fighters_scraped += 1
          
          # 日本語名を取得
          japanese_name = extract_japanese_name(element)
          
          # ローマ字名を取得
          english_name = extract_english_name(element)
          
          if japanese_name && english_name
            process_fighter_data(japanese_name, english_name, fighters_created, errors)
          else
            errors << "Failed to extract names from element: #{element.to_s[0..100]}"
          end
        end
      end

      puts "\nScraping completed!"
      puts "Elements processed: #{fighters_scraped}"
      puts "Fighters created: #{fighters_created}"
      puts "Errors: #{errors.length}"
      
      if errors.any?
        puts "\nErrors encountered:"
        errors.first(10).each { |error| puts "- #{error}" }
        puts "... and #{errors.length - 10} more errors" if errors.length > 10
      end

    rescue => e
      puts "Error occurred during scraping: #{e.message}"
      puts e.backtrace.first(5)
    ensure
      # Seleniumドライバーを終了
      driver&.quit
      puts "Firefox browser closed"
    end
  end

  private

  def extract_japanese_name(element)
    # 日本語名の抽出パターン
    japanese_selectors = [
      '.name-ja',
      '.japanese-name',
      '.fighter-name-ja',
      '.name'
    ]
    
    japanese_selectors.each do |selector|
      name_element = element.css(selector).first
      if name_element && name_element.text.match?(/[一-龯ひらがなカタカナ]/)
        return name_element.text.strip
      end
    end
    
    # セレクターで見つからない場合、テキスト全体から日本語を抽出
    text = element.text
    japanese_match = text.match(/([一-龯ひらがなカタカナ々〆〤\s]+)/)
    japanese_match ? japanese_match[1].strip : nil
  end

  def extract_english_name(element)
    # ローマ字名の抽出パターン
    english_selectors = [
      '.name-en',
      '.english-name',
      '.fighter-name-en',
      '.romaji'
    ]
    
    english_selectors.each do |selector|
      name_element = element.css(selector).first
      if name_element && name_element.text.match?(/^[A-Za-z\s]+$/)
        return name_element.text.strip
      end
    end
    
    # セレクターで見つからない場合、テキスト全体からアルファベットを抽出
    text = element.text
    english_match = text.match(/([A-Z][a-z]+(?:\s+[A-Z][a-z]+)*)/)
    english_match ? english_match[1].strip : nil
  end

  def process_fighter_data(japanese_name, english_name, fighters_created, errors)
    begin
      # スクレイピングで取得した値をそのまま保存（絶対に変換しない）
      full_name_value = japanese_name.strip
      full_name_english_value = english_name.strip
      
      puts "DEBUG: Before saving to DB - full_name: '#{full_name_value}', full_name_english: '#{full_name_english_value}'"
      
      # ひらがな名を生成（full_name_hiragana用のみ）
      if full_name_value.match?(/[ア-ヴ]/) # カタカナが含まれている場合（外国人選手）
        hiragana_name = katakana_to_hiragana(full_name_value)
      else # 漢字・ひらがなの場合（日本人選手）
        hiragana_name = generate_hiragana_from_romaji(full_name_english_value)
      end
      
      # 既存の選手をチェック
      existing_fighter = Fighter.find_by(
        full_name: full_name_value
      ) || Fighter.find_by(
        full_name_english: full_name_english_value
      )
      
      if existing_fighter
        puts "Skipping existing fighter: #{full_name_value} (#{full_name_english_value})"
        return
      end

      # 新しい選手を作成（スクレイピング値をそのまま保存）
      fighter = Fighter.create!(
        full_name: full_name_value,
        full_name_english: full_name_english_value,
        full_name_hiragana: hiragana_name,
        ring_name: nil,
        ring_name_hiragana: nil,
        is_active: true
      )
      
      puts "Created fighter: #{fighter.full_name} (#{fighter.full_name_english}) - #{fighter.full_name_hiragana}"
      fighters_created += 1
      
    rescue => e
      error_msg = "Failed to create fighter '#{japanese_name}' (#{english_name}): #{e.message}"
      errors << error_msg
      puts error_msg
    end
  end


  def generate_hiragana_from_romaji(english_name)
    begin
      # まず手動変換を試行（より正確）
      hiragana = manual_romaji_to_hiragana(english_name)
      
      # 手動変換で変換されなかった部分があればromajigemを使用
      if hiragana.match?(/[a-zA-Z]/)
        romaji_converted = Romaji.kana(english_name.downcase)
        # romajigemが有効な変換を行った場合は使用
        if romaji_converted != english_name.downcase && !romaji_converted.match?(/[a-zA-Z]/)
          hiragana = romaji_converted
        end
      end
      
      hiragana
    rescue
      # 変換に失敗した場合は手動変換のみを試行
      manual_romaji_to_hiragana(english_name)
    end
  end

  def manual_romaji_to_hiragana(romaji)
    # よくあるローマ字→ひらがな変換パターン（拡張版）
    conversion_table = {
      # 基本の母音
      'a' => 'あ', 'i' => 'い', 'u' => 'う', 'e' => 'え', 'o' => 'お',
      
      # か行
      'ka' => 'か', 'ki' => 'き', 'ku' => 'く', 'ke' => 'け', 'ko' => 'こ',
      'kya' => 'きゃ', 'kyu' => 'きゅ', 'kyo' => 'きょ',
      
      # が行
      'ga' => 'が', 'gi' => 'ぎ', 'gu' => 'ぐ', 'ge' => 'げ', 'go' => 'ご',
      'gya' => 'ぎゃ', 'gyu' => 'ぎゅ', 'gyo' => 'ぎょ',
      
      # さ行
      'sa' => 'さ', 'shi' => 'し', 'su' => 'す', 'se' => 'せ', 'so' => 'そ',
      'sha' => 'しゃ', 'shu' => 'しゅ', 'sho' => 'しょ',
      
      # ざ行
      'za' => 'ざ', 'ji' => 'じ', 'zu' => 'ず', 'ze' => 'ぜ', 'zo' => 'ぞ',
      'ja' => 'じゃ', 'ju' => 'じゅ', 'jo' => 'じょ',
      
      # た行
      'ta' => 'た', 'chi' => 'ち', 'tsu' => 'つ', 'te' => 'て', 'to' => 'と',
      'cha' => 'ちゃ', 'chu' => 'ちゅ', 'cho' => 'ちょ',
      
      # だ行
      'da' => 'だ', 'di' => 'ぢ', 'du' => 'づ', 'de' => 'で', 'do' => 'ど',
      
      # な行
      'na' => 'な', 'ni' => 'に', 'nu' => 'ぬ', 'ne' => 'ね', 'no' => 'の',
      'nya' => 'にゃ', 'nyu' => 'にゅ', 'nyo' => 'にょ',
      
      # は行
      'ha' => 'は', 'hi' => 'ひ', 'fu' => 'ふ', 'he' => 'へ', 'ho' => 'ほ',
      'hya' => 'ひゃ', 'hyu' => 'ひゅ', 'hyo' => 'ひょ',
      
      # ば行
      'ba' => 'ば', 'bi' => 'び', 'bu' => 'ぶ', 'be' => 'べ', 'bo' => 'ぼ',
      'bya' => 'びゃ', 'byu' => 'びゅ', 'byo' => 'びょ',
      
      # ぱ行
      'pa' => 'ぱ', 'pi' => 'ぴ', 'pu' => 'ぷ', 'pe' => 'ぺ', 'po' => 'ぽ',
      'pya' => 'ぴゃ', 'pyu' => 'ぴゅ', 'pyo' => 'ぴょ',
      
      # ま行
      'ma' => 'ま', 'mi' => 'み', 'mu' => 'む', 'me' => 'め', 'mo' => 'も',
      'mya' => 'みゃ', 'myu' => 'みゅ', 'myo' => 'みょ',
      
      # や行
      'ya' => 'や', 'yu' => 'ゆ', 'yo' => 'よ',
      
      # ら行
      'ra' => 'ら', 'ri' => 'り', 'ru' => 'る', 're' => 'れ', 'ro' => 'ろ',
      'rya' => 'りゃ', 'ryu' => 'りゅ', 'ryo' => 'りょ',
      
      # わ行・ん
      'wa' => 'わ', 'wo' => 'を', 'n' => 'ん',
      
      # 特殊な組み合わせ
      'kk' => 'っk', 'pp' => 'っp', 'tt' => 'っt', 'ss' => 'っs'
    }
    
    # 名前を分解して変換
    words = romaji.downcase.split
    hiragana_words = []
    
    words.each do |word|
      hiragana_word = ""
      i = 0
      while i < word.length
        found = false
        # 長い音から順に検索（4文字から1文字まで）
        (4).downto(1) do |length|
          if i + length <= word.length
            substr = word[i, length]
            if conversion_table[substr]
              hiragana_word += conversion_table[substr]
              i += length
              found = true
              break
            end
          end
        end
        
        unless found
          # 変換できない文字はそのまま残す
          hiragana_word += word[i]
          i += 1
        end
      end
      hiragana_words << hiragana_word
    end
    
    hiragana_words.join(' ')
  end


  def katakana_to_hiragana(katakana_text)
    # カタカナをひらがなに変換するシンプルな変換
    hiragana_text = katakana_text.tr('ア-ヴ', 'あ-ゔ')
    hiragana_text
  end

  def romaji_to_katakana(romaji)
    # シンプルなローマ字→カタカナ変換（基本的な音のみ）
    katakana_table = {
      'a' => 'ア', 'i' => 'イ', 'u' => 'ウ', 'e' => 'エ', 'o' => 'オ',
      'ka' => 'カ', 'ki' => 'キ', 'ku' => 'ク', 'ke' => 'ケ', 'ko' => 'コ',
      'ga' => 'ガ', 'gi' => 'ギ', 'gu' => 'グ', 'ge' => 'ゲ', 'go' => 'ゴ',
      'sa' => 'サ', 'shi' => 'シ', 'su' => 'ス', 'se' => 'セ', 'so' => 'ソ',
      'za' => 'ザ', 'ji' => 'ジ', 'zu' => 'ズ', 'ze' => 'ゼ', 'zo' => 'ゾ',
      'ta' => 'タ', 'chi' => 'チ', 'tsu' => 'ツ', 'te' => 'テ', 'to' => 'ト',
      'da' => 'ダ', 'de' => 'デ', 'do' => 'ド',
      'na' => 'ナ', 'ni' => 'ニ', 'nu' => 'ヌ', 'ne' => 'ネ', 'no' => 'ノ',
      'ha' => 'ハ', 'hi' => 'ヒ', 'fu' => 'フ', 'he' => 'ヘ', 'ho' => 'ホ',
      'ba' => 'バ', 'bi' => 'ビ', 'bu' => 'ブ', 'be' => 'ベ', 'bo' => 'ボ',
      'pa' => 'パ', 'pi' => 'ピ', 'pu' => 'プ', 'pe' => 'ペ', 'po' => 'ポ',
      'ma' => 'マ', 'mi' => 'ミ', 'mu' => 'ム', 'me' => 'メ', 'mo' => 'モ',
      'ya' => 'ヤ', 'yu' => 'ユ', 'yo' => 'ヨ',
      'ra' => 'ラ', 'ri' => 'リ', 'ru' => 'ル', 're' => 'レ', 'ro' => 'ロ',
      'wa' => 'ワ', 'n' => 'ン'
    }
    
    words = romaji.downcase.split
    katakana_words = []
    
    words.each do |word|
      katakana_word = ""
      i = 0
      while i < word.length
        found = false
        (3).downto(1) do |length|
          if i + length <= word.length
            substr = word[i, length]
            if katakana_table[substr]
              katakana_word += katakana_table[substr]
              i += length
              found = true
              break
            end
          end
        end
        
        unless found
          # 変換できない文字は大文字で近似
          case word[i]
          when 'b' then katakana_word += 'ブ'
          when 'c' then katakana_word += 'ク'
          when 'd' then katakana_word += 'ド'
          when 'f' then katakana_word += 'フ'
          when 'g' then katakana_word += 'グ'
          when 'h' then katakana_word += 'ハ'
          when 'j' then katakana_word += 'ジ'
          when 'k' then katakana_word += 'ク'
          when 'l' then katakana_word += 'ル'
          when 'm' then katakana_word += 'ム'
          when 'p' then katakana_word += 'プ'
          when 'r' then katakana_word += 'ル'
          when 's' then katakana_word += 'ス'
          when 't' then katakana_word += 'ト'
          when 'v' then katakana_word += 'ヴ'
          when 'w' then katakana_word += 'ワ'
          when 'x' then katakana_word += 'クス'
          when 'y' then katakana_word += 'ヤ'
          when 'z' then katakana_word += 'ズ'
          else
            katakana_word += word[i].upcase
          end
          i += 1
        end
      end
      katakana_words << katakana_word
    end
    
    katakana_words.join(' ')
  end
end
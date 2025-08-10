require 'net/http'
require 'uri'
require 'json'

class GeminiService
  API_KEY = Rails.application.credentials.dig(:gemini_api_key) || ENV['GEMINI_API_KEY']
  BASE_URL = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp:generateContent'

  class APIError < StandardError; end

  def self.generate_fighter_features(fighter)
    new(fighter).generate_features
  end

  def initialize(fighter)
    @fighter = fighter
    raise ArgumentError, 'Fighter is required' unless fighter
    # API キーのチェックは generate_features メソッドで行う
  end

  def generate_features
    # API キーがない場合はテストデータを返す
    if API_KEY.blank?
      Rails.logger.warn "Gemini API key not configured, returning test data"
      return generate_test_features
    end
    
    prompt = build_prompt
    
    begin
      response = make_api_request(prompt)
      parse_response(response)
    rescue => e
      Rails.logger.error "Gemini API error for fighter #{@fighter.id}: #{e.message}"
      raise APIError, "特徴の生成に失敗しました: #{e.message}"
    end
  end

  private

  def build_prompt
    <<~PROMPT
      あなたは格闘技の専門家です。#{@fighter.full_name} 選手について、
      Wikipediaなどの公開情報を参考に、クイズゲーム用の特徴を生成してください。

      以下の形式で、JSON形式で30個程度の特徴を出力してください：

      {
        "features": [
          {
            "category": "階級",
            "level": 3,
            "feature": "フェザー級"
          },
          {
            "category": "戦績",
            "level": 1,
            "feature": "vsクレベル・コイケ 5分3R終了 判定2-1で勝利"
          }
        ]
      }

      ルール：
      - category: 階級、戦績、来歴、通称、所属、ファイトスタイル、その他 のいずれか
      - level1（具体性が高い）: その人固有の詳細な特徴
      - level2（普通）: 中程度の特徴
      - level3（抽象性が高い）: 誰にでも当てはまりそうな簡単な特徴
      - 階級はlevel3、通称はlevel1、ファイトスタイルはlevel3、戦績はlevel1で設定
      - 戦績は直近5試合程度の勝敗を含める
        - 5試合分は必ず含めること
      - ファイトスタイルは以下は必ず判定する
        - ストライカー・グラップラー・オールラウンダー・レスラー
      - 適切なカテゴリがない場合は「その他」を使用
      - 1つの特徴は1文で表現
      - 事実に基づいた情報のみ使用
      - 存在しない情報は作成しない

      JSONのみを出力し、説明文は不要です。
    PROMPT
  end

  def make_api_request(prompt)
    uri = URI("#{BASE_URL}?key=#{API_KEY}")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    
    request = Net::HTTP::Post.new(uri)
    request['Content-Type'] = 'application/json'
    request.body = {
      contents: [{
        parts: [{
          text: prompt
        }]
      }],
      generationConfig: {
        temperature: 0.7,
        topK: 40,
        topP: 0.8,
        maxOutputTokens: 2048,
      }
    }.to_json

    response = http.request(request)
    
    unless response.code == '200'
      raise APIError, "API request failed: #{response.code} - #{response.body}"
    end

    JSON.parse(response.body)
  end

  def parse_response(response)
    begin
      # Gemini APIのレスポンス構造に従って解析
      text_content = response.dig('candidates', 0, 'content', 'parts', 0, 'text')
      raise APIError, 'No content in response' unless text_content

      # JSON部分のみを抽出（余分な説明テキストがある場合）
      json_match = text_content.match(/\{.*\}/m)
      json_text = json_match ? json_match[0] : text_content

      parsed_json = JSON.parse(json_text)
      
      unless parsed_json['features'].is_a?(Array)
        raise APIError, 'Invalid response format: features array not found'
      end

      # 各特徴のバリデーション
      parsed_json['features'].each do |feature|
        validate_feature(feature)
      end

      parsed_json['features']
    rescue JSON::ParserError => e
      raise APIError, "Failed to parse JSON response: #{e.message}"
    end
  end

  def validate_feature(feature)
    required_keys = %w[category level feature]
    missing_keys = required_keys - feature.keys
    
    if missing_keys.any?
      raise APIError, "Missing required keys in feature: #{missing_keys.join(', ')}"
    end

    unless (1..3).include?(feature['level'])
      raise APIError, "Invalid level: #{feature['level']} (must be 1-3)"
    end

    valid_categories = %w[階級 戦績 来歴 通称 所属 ファイトスタイル その他]
    unless valid_categories.include?(feature['category'])
      raise APIError, "Invalid category: #{feature['category']}"
    end

    if feature['feature'].blank?
      raise APIError, "Feature text cannot be blank"
    end
  end

  def generate_test_features
    fighter_name = @fighter.full_name
    
    [
      # 階級関連（レベル3：簡単）
      {
        "category" => "階級",
        "level" => 3,
        "feature" => "フェザー級"
      },
      {
        "category" => "階級", 
        "level" => 3,
        "feature" => "プロ格闘家"
      },
      
      # 戦績関連（レベル1：難しい）
      {
        "category" => "戦績",
        "level" => 1,
        "feature" => "vs田中太郎 5分3R終了 判定2-1で勝利"
      },
      {
        "category" => "戦績",
        "level" => 1,
        "feature" => "vs佐藤次郎 2R TKO勝利"
      },
      {
        "category" => "戦績",
        "level" => 1,
        "feature" => "通算戦績15勝3敗"
      },
      
      # 来歴関連（レベル2：普通）
      {
        "category" => "来歴",
        "level" => 2,
        "feature" => "2018年にプロデビュー"
      },
      {
        "category" => "来歴",
        "level" => 2,
        "feature" => "高校時代にレスリングで全国大会出場"
      },
      {
        "category" => "来歴",
        "level" => 2,
        "feature" => "大学卒業後に格闘技転向"
      },
      
      # 通称関連（レベル1：難しい）
      {
        "category" => "通称",
        "level" => 1,
        "feature" => "#{fighter_name}の愛称で親しまれる"
      },
      {
        "category" => "通称",
        "level" => 1,
        "feature" => "ファンからは「○○」と呼ばれる"
      },
      
      # 所属関連（レベル2：普通）
      {
        "category" => "所属",
        "level" => 2,
        "feature" => "パラエストラ東京所属"
      },
      {
        "category" => "所属",
        "level" => 2,
        "feature" => "○○ジム所属"
      },
      
      # ファイトスタイル関連（レベル3：簡単）
      {
        "category" => "ファイトスタイル",
        "level" => 3,
        "feature" => "ストライカー"
      },
      {
        "category" => "ファイトスタイル",
        "level" => 3,
        "feature" => "打撃が得意"
      },
      {
        "category" => "ファイトスタイル",
        "level" => 3,
        "feature" => "レスリングベース"
      },
      
      # その他
      {
        "category" => "その他",
        "level" => 2,
        "feature" => "身長175cm"
      },
      {
        "category" => "その他",
        "level" => 2,
        "feature" => "体重65kg"
      },
      {
        "category" => "その他",
        "level" => 3,
        "feature" => "日本人"
      },
      {
        "category" => "その他",
        "level" => 1,
        "feature" => "趣味は読書"
      },
      {
        "category" => "その他",
        "level" => 1,
        "feature" => "好きな食べ物は寿司"
      }
    ]
  end
end
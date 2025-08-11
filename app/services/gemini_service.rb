require 'net/http'
require 'uri'
require 'json'

class GeminiService
  API_KEY = Rails.application.credentials.dig(:gemini_api_key) || ENV['GEMINI_API_KEY']
  BASE_URL = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-pro:generateContent'

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
      Wikipedia（https://ja.wikipedia.org/wiki/#{@fighter.full_name}）の情報のみを用いて、クイズゲーム用の特徴を生成してください。
      Wikipediaの情報以外は絶対に使わないでください。
      脚注の項目は絶対に含めないでください。

      以下の形式で、JSON形式で20個程度の特徴を出力してください：

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
      - 戦績は直近5試合程度の勝敗を含める（どの格闘家も大体戦績の項目があるのでそこから選定して）
        - 5試合分は必ず含めること
      - ファイトスタイルは以下は必ず判定する
        - ストライカー・グラップラー・オールラウンダー・レスラー
      - 通称は基本情報に大体含まれているので、そこから選定
      - 適切なカテゴリがない場合は「その他」を使用
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
    
    request_body = {
      contents: [{
        parts: [{
          text: prompt
        }]
      }],
      generationConfig: {
        temperature: 0.7,
        topK: 40,
        topP: 0.8,
        maxOutputTokens: 4500, # 2.0の場合は2048に設定する。
      }
    }
    
    Rails.logger.info "Sending request to Gemini API: #{request_body.to_json}"
    request.body = request_body.to_json

    response = http.request(request)
    
    Rails.logger.info "Gemini API response code: #{response.code}"
    Rails.logger.info "Gemini API response body: #{response.body}"
    
    unless response.code == '200'
      Rails.logger.error "API request failed: #{response.code} - #{response.body}"
      raise APIError, "API request failed: #{response.code} - #{response.body}"
    end

    parsed_response = JSON.parse(response.body)
    Rails.logger.info "Parsed response: #{parsed_response}"
    parsed_response
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
end
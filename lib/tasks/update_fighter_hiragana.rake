namespace :fighters do
  desc "Update fighter hiragana using Gemini API (100 at a time)"
  task update_hiragana: :environment do
    require 'httparty'
    require 'json'
    
    api_key = ENV['GEMINI_API_KEY']
    if api_key.blank?
      puts "Error: GEMINI_API_KEY environment variable not set"
      exit 1
    end
    
    batch_size = 100
    fighters = Fighter.all
    total_count = fighters.count
    processed = 0
    
    puts "Starting hiragana update for #{total_count} fighters..."
    puts "Processing in batches of #{batch_size}..."
    
    fighters.find_in_batches(batch_size: batch_size) do |fighter_batch|
      puts "\nProcessing batch #{processed / batch_size + 1}/#{(total_count.to_f / batch_size).ceil}..."
      puts "Fighters in this batch: #{fighter_batch.size}"
      
      # Prepare names for API request
      names = fighter_batch.map(&:full_name)
      
      # Create prompt for all names in this batch
      prompt = build_prompt(names)
      
      begin
        # Call Gemini API
        response = call_gemini_api(api_key, prompt)
        hiragana_map = parse_response(response)
        
        if hiragana_map.nil? || hiragana_map.empty?
          puts "Warning: Failed to parse API response"
          next
        end
        
        # Update database
        fighter_batch.each do |fighter|
          hiragana = hiragana_map[fighter.full_name]
          if hiragana.present?
            fighter.update!(full_name_hiragana: hiragana)
            puts "Updated #{fighter.full_name} → #{hiragana}"
          else
            puts "Warning: No hiragana found for #{fighter.full_name}"
          end
        end
        
        processed += fighter_batch.size
        puts "Progress: #{processed}/#{total_count} (#{(processed.to_f / total_count * 100).round(1)}%)"
        
        # Rate limiting - wait 1 second between batches
        sleep(1)
        
      rescue => e
        puts "Error processing batch: #{e.message}"
        puts "Skipping this batch and continuing..."
        next
      end
    end
    
    puts "\nCompleted! Updated hiragana for #{processed} fighters."
  end
  
  private
  
  def build_prompt(names)
    <<~PROMPT
      以下の名前を全て「ひらがな」に変換してください。
      カタカナ、漢字、英字などすべての文字を「ひらがな」に変換することが必須です。
      
      重要なルール：
      1. カタカナ表記の名前も必ず「ひらがな」に変換してください
      2. 「ー」は長音として適切なひらがなに変換（例：ピーター → ぴーたー、ジョー → じょう）
      3. 外国人名もカタカナ読みをひらがなに変換してください
      4. スペースは半角スペースのまま残してください
      
      必ずJSON形式で、元の名前をキー、ひらがなを値としたオブジェクトを返してください。
      
      入力する名前:
      #{names.to_json}
      
      出力例:
      {
        "田中 太郎": "たなか たろう",
        "ヤマダ ジロウ": "やまだ じろう",
        "ピーター アーツ": "ぴーたー あーつ",
        "ジョー コックス": "じょう こっくす",
        "マイク タイソン": "まいく たいそん"
      }
      
      JSONのみを出力してください。説明文は不要です。
      全ての名前を必ず「ひらがな」のみで返してください。
    PROMPT
  end
  
  def call_gemini_api(api_key, prompt)
    url = "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent?key=#{api_key}"
    
    headers = {
      'Content-Type' => 'application/json'
    }
    
    body = {
      contents: [
        {
          parts: [
            {
              text: prompt
            }
          ]
        }
      ],
      generationConfig: {
        temperature: 0.1,
        maxOutputTokens: 2048
      }
    }
    
    response = HTTParty.post(url, 
      headers: headers,
      body: body.to_json,
      timeout: 30
    )
    
    if response.code != 200
      raise "API request failed with code #{response.code}: #{response.body}"
    end
    
    response.parsed_response
  end
  
  def parse_response(response)
    content = response.dig('candidates', 0, 'content', 'parts', 0, 'text')
    if content.blank?
      puts "Warning: Empty response from API"
      return nil
    end
    
    # Extract JSON from response (remove markdown code blocks if present)
    json_text = content.gsub(/```json\s*/, '').gsub(/```\s*/, '').strip
    
    begin
      # Parse JSON response
      result = JSON.parse(json_text)
      puts "Successfully parsed #{result.keys.size} name mappings"
      result
    rescue JSON::ParserError => e
      puts "Error parsing JSON response: #{e.message}"
      puts "Response content: #{json_text[0..500]}..." if json_text.length > 500
      nil
    end
  end
end
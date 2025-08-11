require_relative '../services/gemini_service'

class FightersController < ApplicationController
  before_action :authenticate_user!, only: [:new, :create, :edit, :update, :destroy, :features, :create_features, :generate_ai_features]
  before_action :ensure_admin, only: [:new, :create, :edit, :update, :destroy, :features, :create_features, :generate_ai_features]
  before_action :set_fighter, only: [:show, :edit, :update, :destroy, :features, :create_features, :generate_ai_features]
  
  def index
    query = params[:query] || params[:q]
    
    if query.present?
      @fighters = Fighter.active.search_by_hiragana(query)
      @query = query
      
      # 候補が1件に絞り込まれた場合のフラグ
      @single_candidate = @fighters.count == 1 ? @fighters.first : nil
    else
      # パラメータがない場合のみRedisキャッシュを使用
      respond_to do |format|
        format.html do
          cache_key = "fighters:index:all"
          
          @fighters = Rails.cache.fetch(cache_key, expires_in: 1.hour) do
            Rails.logger.info "Cache miss for fighters index HTML - loading from database"
            Fighter.active.order(:full_name).to_a  # to_aで配列化して保存
          end
          
          Rails.logger.info "Fighters loaded from cache for HTML: #{@fighters.size} records"
        end
        
        format.json do
          # JSON用は別途キャッシュ（シリアライズ済みデータを保存）
          json_cache_key = "fighters:index:json:all"

          json_response = Rails.cache.fetch(json_cache_key, expires_in: 1.hour) do
            Rails.logger.info "Cache miss for fighters index JSON - loading from database"
            Fighter.active.order(:full_name).map { |f| 
              { 
                id: f.id, 
                full_name: f.full_name,
                full_name_hiragana: f.full_name_hiragana,
                display_name: f.display_name 
              } 
            }
          end
          
          render json: json_response
        end
      end
      
      return # 早期リターンでqueryなしの処理を終了
    end
    
    # query.present?の場合の処理（キャッシュなし）
    respond_to do |format|
      format.html
      format.json do
        render json: @fighters.map { |f| 
          { 
            id: f.id, 
            full_name: f.full_name,
            full_name_hiragana: f.full_name_hiragana,
            display_name: f.display_name 
          } 
        }
      end
    end
  end

  def show
  end
  
  def new
    @fighter = Fighter.new
  end
  
  def create
    @fighter = Fighter.new(fighter_params)
    
    if @fighter.save
      # キャッシュをクリア
      clear_fighters_cache
      redirect_to @fighter, notice: '選手を作成しました。'
    else
      render :new
    end
  end
  
  def edit
  end
  
  def update
    if @fighter.update(fighter_params)
      # キャッシュをクリア
      clear_fighters_cache
      redirect_to @fighter, notice: '選手情報を更新しました。'
    else
      render :edit
    end
  end
  
  def destroy
    @fighter.destroy
    # キャッシュをクリア
    clear_fighters_cache
    redirect_to fighters_path, notice: '選手を削除しました。'
  end

  # 特徴管理画面
  def features
    @categories = FighterFeatureCategory.all
    @features = @fighter.fighter_features.includes(:fighter_feature_category)
  end

  # 特徴の一括作成
  def create_features
    features_params = params[:features] || {}
    created_count = 0
    errors = []

    ActiveRecord::Base.transaction do
      features_params.each do |index, feature_data|
        next if feature_data[:feature].blank?

        feature = @fighter.fighter_features.build(
          feature: feature_data[:feature],
          level: feature_data[:level].to_i,
          fighter_feature_category_id: feature_data[:category_id].to_i
        )

        if feature.save
          created_count += 1
        else
          errors << "#{index.to_i + 1}行目: #{feature.errors.full_messages.join(', ')}"
        end
      end

      if errors.any?
        raise ActiveRecord::Rollback
      end
    end

    if errors.any?
      redirect_to features_fighter_path(@fighter), alert: "エラーが発生しました: #{errors.join('; ')}"
    else
      redirect_to features_fighter_path(@fighter), notice: "#{created_count}件の特徴を作成しました。"
    end
  end

  # AI特徴生成（戦績も含む）
  def generate_ai_features
    respond_to do |format|
      format.json do
        begin
          # AIで基本特徴を生成
          ai_features_data = GeminiService.generate_fighter_features(@fighter)
          
          # AIが生成した戦績カテゴリの特徴を除去
          filtered_ai_features = ai_features_data.reject { |feature| feature['category'] == '戦績' }

          # Wikipediaから戦績データを直接取得
          fight_records = WikipediaService.fetch_fighter_records(@fighter.full_name)

          # 戦績データをFeature形式に変換（最新5試合）
          record_features = convert_records_to_features(fight_records.first(5))
          
          # Wikipediaから基本情報を直接取得
          basic_info_data = WikipediaService.fetch_fighter_basic_info(@fighter.full_name)
          basic_info_features = convert_basic_info_to_features(basic_info_data)
          
          # フィルタ済みAI特徴、戦績特徴、基本情報特徴をマージ
          all_features = filtered_ai_features + record_features + basic_info_features
          
          # カテゴリIDを追加
          enhanced_features = all_features.map do |feature|
            category = FighterFeatureCategory.find_by(name: feature['category'])
            feature.merge({
              'category_id' => category&.id
            })
          end
          
          render json: { 
            success: true, 
            features: enhanced_features,
            record_count: record_features.length,
            basic_info_count: basic_info_features.length,
            ai_count: filtered_ai_features.length,
            ai_original_count: ai_features_data.length,
            ai_filtered_count: ai_features_data.length - filtered_ai_features.length,
            total_count: all_features.length
          }
        rescue GeminiService::APIError => e
          render json: { success: false, error: e.message }, status: :unprocessable_entity
        rescue => e
          Rails.logger.error "Unexpected error in AI feature generation: #{e.message}"
          render json: { success: false, error: '予期しないエラーが発生しました' }, status: :internal_server_error
        end
      end
    end
  end
  
  private
  
  def set_fighter
    @fighter = Fighter.find(params[:id])
  end
  
  def convert_records_to_features(fight_records)
    features = []
    
    fight_records.each do |record|
      next unless record[:opponent].present?
      
      # 基本的な戦績情報を特徴として追加
      result_text = case record[:result]
                   when '○' then '勝利'
                   when '×' then '敗北'
                   else record[:result]
                   end
      
      # より読みやすいフォーマットに整理
      feature_text = ""
      
      # 日付
      feature_text += "#{record[:date]} " if record[:date].present?
      
      # 大会名
      feature_text += "#{record[:event]}で " if record[:event].present?
      
      # 対戦相手と結果
      if record[:opponent].present?
        feature_text += "#{record[:opponent]}に#{result_text}"
      end
      
      # 決着方法、ラウンド、時間
      if record[:method].present? || record[:round].present? || record[:time].present?
        method_parts = []
        method_parts << record[:method] if record[:method].present?
        method_parts << record[:round] if record[:round].present?
        method_parts << record[:time] if record[:time].present?
        
        if method_parts.any?
          feature_text += " (#{method_parts.join(' ')})"
        end
      end
      
      features << {
        'category' => '戦績',
        'level' => 1,  # 戦績は具体性が高いのでlevel 1
        'feature' => feature_text
      }
    end
    
    features
  end
  
  def convert_basic_info_to_features(basic_info_data)
    # WikipediaServiceから取得した基本情報データをFeature形式に変換
    basic_info_data.map do |info|
      {
        'category' => info[:category],
        'level' => info[:level],
        'feature' => info[:feature]
      }
    end
  end
  
  def ensure_admin
    unless current_user&.admin?
      redirect_to root_path, alert: '管理者権限が必要です。'
    end
  end
  
  def fighter_params
    params.require(:fighter).permit(:full_name, :full_name_english, :full_name_hiragana, 
                                    :ring_name, :ring_name_hiragana, :image_url, :is_active)
  end
  
  def clear_fighters_cache
    Rails.cache.delete("fighters:index:all")
    Rails.cache.delete("fighters:index:json:all")
    Rails.logger.info "Fighters cache cleared"
  end
end

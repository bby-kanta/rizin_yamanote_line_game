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
      @fighters = Fighter.active.order(:full_name)
    end
    
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
      redirect_to @fighter, notice: '選手を作成しました。'
    else
      render :new
    end
  end
  
  def edit
  end
  
  def update
    if @fighter.update(fighter_params)
      redirect_to @fighter, notice: '選手情報を更新しました。'
    else
      render :edit
    end
  end
  
  def destroy
    @fighter.destroy
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

  # AI特徴生成
  def generate_ai_features
    respond_to do |format|
      format.json do
        begin
          features_data = GeminiService.generate_fighter_features(@fighter)
          
          # カテゴリIDを追加
          enhanced_features = features_data.map do |feature|
            category = FighterFeatureCategory.find_by(name: feature['category'])
            feature.merge({
              'category_id' => category&.id
            })
          end
          
          render json: { success: true, features: enhanced_features }
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
  
  def ensure_admin
    unless current_user&.admin?
      redirect_to root_path, alert: '管理者権限が必要です。'
    end
  end
  
  def fighter_params
    params.require(:fighter).permit(:full_name, :full_name_english, :full_name_hiragana, 
                                    :ring_name, :ring_name_hiragana, :image_url, :is_active)
  end
end

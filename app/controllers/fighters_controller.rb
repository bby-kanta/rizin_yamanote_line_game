class FightersController < ApplicationController
  before_action :authenticate_user!, only: [:new, :create, :edit, :update, :destroy]
  before_action :ensure_admin, only: [:new, :create, :edit, :update, :destroy]
  before_action :set_fighter, only: [:show, :edit, :update, :destroy]
  
  def index
    if params[:query].present?
      @fighters = Fighter.active.search_by_hiragana(params[:query]).limit(10)
      @query = params[:query]
      
      # 候補が1件に絞り込まれた場合のフラグ
      @single_candidate = @fighters.count == 1 ? @fighters.first : nil
    else
      @fighters = Fighter.active.limit(20)
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

class FightersController < ApplicationController
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
    @fighter = Fighter.find(params[:id])
  end
end

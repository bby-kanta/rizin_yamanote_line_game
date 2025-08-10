class HomeController < ApplicationController
  def index
    @recent_sessions = GameSession.finished
                                  .includes(:creator, :winner_user, :game_players => :user)
                                  .order(ended_at: :desc)
                                  .limit(5)
  end
end

class GameChannel < ApplicationCable::Channel
  def subscribed
    game_session = GameSession.find(params[:game_session_id])
    
    # ユーザーがこのゲームセッションに参加しているかチェック
    if current_user.joined_game?(game_session)
      stream_from "game_session_#{params[:game_session_id]}"
      Rails.logger.info "User #{current_user.name} subscribed to game session #{params[:game_session_id]}"
    else
      reject
    end
  end

  def unsubscribed
    Rails.logger.info "User #{current_user&.name} unsubscribed from game channel"
  end
end

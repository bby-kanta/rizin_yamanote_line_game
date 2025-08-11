class QuizSessionChannel < ApplicationCable::Channel
  def subscribed
    @quiz_session = QuizSession.find(params[:quiz_session_id])
    @participant = @quiz_session.participant_for(current_user)
    
    stream_from "quiz_session_#{@quiz_session.id}"
    
    Rails.logger.info "QuizSessionChannel: User #{current_user.id} subscribing to session #{@quiz_session.id}"
    
    # 参加者を接続済みとしてマーク
    @participant.mark_connected!
    @quiz_session.reload  # セッションをリロードして最新状態を取得
    
    Rails.logger.info "QuizSessionChannel: After marking connected - connected: #{@quiz_session.quiz_participants.connected.count}, total: #{@quiz_session.quiz_participants.count}"
    
    # 全員の接続状況をブロードキャスト
    connection_data = {
      type: 'connection_updated',
      connected_count: @quiz_session.quiz_participants.connected.count,
      total_count: @quiz_session.quiz_participants.count,
      all_connected: @quiz_session.all_participants_connected?
    }
    
    Rails.logger.info "QuizSessionChannel: Broadcasting connection data: #{connection_data}"
    ActionCable.server.broadcast("quiz_session_#{@quiz_session.id}", connection_data)
  end

  def unsubscribed
    # 参加者を切断済みとしてマーク
    if @participant
      Rails.logger.info "QuizSessionChannel: User #{current_user&.id} unsubscribing from session #{@quiz_session&.id}"
      @participant.mark_disconnected!
      @quiz_session.reload if @quiz_session
      
      # 全員の接続状況をブロードキャスト
      connection_data = {
        type: 'connection_updated',
        connected_count: @quiz_session.quiz_participants.connected.count,
        total_count: @quiz_session.quiz_participants.count,
        all_connected: @quiz_session.all_participants_connected?
      }
      
      Rails.logger.info "QuizSessionChannel: Broadcasting disconnection data: #{connection_data}"
      ActionCable.server.broadcast("quiz_session_#{@quiz_session.id}", connection_data)
    end
  end
end

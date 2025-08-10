class QuizSessionChannel < ApplicationCable::Channel
  def subscribed
    quiz_session = QuizSession.find(params[:quiz_session_id])
    stream_from "quiz_session_#{quiz_session.id}"
    
    # 接続時に他の参加者に通知
    ActionCable.server.broadcast("quiz_session_#{quiz_session.id}", {
      type: 'user_connected',
      user_id: current_user.id,
      user_name: current_user.name
    })
  end

  def unsubscribed
    # 切断時に他の参加者に通知
    quiz_session_id = params[:quiz_session_id]
    ActionCable.server.broadcast("quiz_session_#{quiz_session_id}", {
      type: 'user_disconnected', 
      user_id: current_user.id,
      user_name: current_user.name
    })
  end
  
  # クライアントからのping受信
  def ping(data)
    # pongを返す
    ActionCable.server.broadcast("quiz_session_#{params[:quiz_session_id]}", {
      type: 'pong',
      user_id: current_user.id,
      timestamp: data['timestamp']
    })
  end
end

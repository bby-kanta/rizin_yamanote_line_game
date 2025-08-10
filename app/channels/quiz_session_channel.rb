class QuizSessionChannel < ApplicationCable::Channel
  def subscribed
    quiz_session = QuizSession.find(params[:quiz_session_id])
    stream_from "quiz_session_#{quiz_session.id}"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end

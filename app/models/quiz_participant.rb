class QuizParticipant < ApplicationRecord
  belongs_to :quiz_session
  belongs_to :user

  validates :miss_count, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :points, presence: true, numericality: { greater_than_or_equal_to: 0 }

  scope :answered, -> { where.not(answered_at: nil) }
  scope :unanswered, -> { where(answered_at: nil) }
  scope :responded, -> { where.not(responded_at: nil) }
  scope :not_responded, -> { where(responded_at: nil) }
  scope :winners, -> { where(is_winner: true) }
  scope :by_points, -> { order(points: :desc, answered_at: :asc) }
  scope :connected, -> { where.not(connected_at: nil) }

  def answered?
    answered_at.present?
  end

  def responded?
    responded_at.present?
  end

  def passed?
    responded_at.present? && answered_at.nil?
  end

  def ranking
    QuizParticipant.where(quiz_session: quiz_session)
                   .where.not(answered_at: nil)
                   .where('points > ? OR (points = ? AND answered_at < ?)', points, points, answered_at || Time.current)
                   .count + 1
  end

  def connected?
    connected_at.present?
  end

  def mark_connected!
    Rails.logger.info "QuizParticipant: Marking user #{user_id} as connected for session #{quiz_session_id}"
    current_time = Time.current
    self.connected_at = current_time
    result = save!
    reload  # DBから最新の状態を取得
    Rails.logger.info "QuizParticipant: Connected at updated to #{connected_at}"
    result
  end

  def mark_disconnected!
    Rails.logger.info "QuizParticipant: Marking user #{user_id} as disconnected for session #{quiz_session_id}"
    self.connected_at = nil
    result = save!
    reload  # DBから最新の状態を取得
    Rails.logger.info "QuizParticipant: Connected at updated to #{connected_at}"
    result
  end
end
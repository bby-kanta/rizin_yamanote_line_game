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
end
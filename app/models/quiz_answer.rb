class QuizAnswer < ApplicationRecord
  belongs_to :quiz_session
  belongs_to :user
  belongs_to :fighter, optional: true

  validates :is_correct, inclusion: { in: [true, false] }
  validates :submitted_at, presence: true

  scope :correct, -> { where(is_correct: true) }
  scope :incorrect, -> { where(is_correct: false) }
  scope :passed, -> { where(fighter_id: nil) }
  scope :recent, -> { order(submitted_at: :desc) }
  scope :for_session, ->(session) { where(quiz_session: session) }
  scope :for_user, ->(user) { where(user: user) }

  def passed?
    fighter_id.nil?
  end
end
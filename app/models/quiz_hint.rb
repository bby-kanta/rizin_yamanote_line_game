class QuizHint < ApplicationRecord
  belongs_to :quiz_session
  belongs_to :fighter_feature
  
  validates :display_order, presence: true, uniqueness: { scope: :quiz_session_id }
  
  scope :ordered, -> { order(:display_order) }
end

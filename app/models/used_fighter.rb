class UsedFighter < ApplicationRecord
  # アソシエーション
  belongs_to :game_session
  belongs_to :fighter
  belongs_to :used_by, class_name: 'User'
  
  # バリデーション
  validates :fighter_id, uniqueness: { scope: :game_session_id }
  validates :used_at, presence: true
  
  # スコープ
  scope :recent, -> { order(used_at: :desc) }
  scope :by_user, ->(user) { where(used_by: user) }
end

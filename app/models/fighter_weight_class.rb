class FighterWeightClass < ApplicationRecord
  # アソシエーション
  belongs_to :fighter
  belongs_to :weight_class
  
  # バリデーション
  validates :fighter_id, uniqueness: { scope: :weight_class_id }
end

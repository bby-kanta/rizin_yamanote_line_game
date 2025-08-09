class WeightClass < ApplicationRecord
  # アソシエーション
  has_many :fighter_weight_classes, dependent: :destroy
  has_many :fighters, through: :fighter_weight_classes
  
  # バリデーション
  validates :japanese_name, presence: true, uniqueness: true
  validates :english_name, presence: true, uniqueness: true
  
  # 表示用の名前
  def display_name
    "#{japanese_name}（#{english_name}）"
  end
end

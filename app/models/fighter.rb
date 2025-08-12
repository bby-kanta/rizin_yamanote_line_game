class Fighter < ApplicationRecord
  # アソシエーション
  has_many :fighter_weight_classes, dependent: :destroy
  has_many :weight_classes, through: :fighter_weight_classes
  has_many :fighter_features, dependent: :destroy
  
  # バリデーション
  validates :full_name, presence: true, uniqueness: true
  validates :full_name_hiragana, presence: true, uniqueness: true
  validates :ring_name, uniqueness: true, allow_blank: true
  validates :is_active, inclusion: { in: [true, false] }
  
  # スコープ
  scope :active, -> { where(is_active: true) }
  scope :inactive, -> { where(is_active: false) }
  
  # インクリメンタルサーチ用のメソッド
  def self.search_by_hiragana(query)
    return none if query.blank?
    
    where("full_name_hiragana LIKE ?", "%#{query}%")
  end
  
  # 表示用の名前
  def display_name
    ring_name.present? ? "#{full_name}（#{ring_name}）" : full_name
  end

  # クイズ用のメソッド
  def quiz_features
    fighter_features
  end

  def has_quiz_features?
    fighter_features.exists?
  end

  # クイズ対象の選手を選出
  def self.quiz_eligible
    joins(:fighter_features).distinct
  end
end

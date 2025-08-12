class FighterFeature < ApplicationRecord
  belongs_to :fighter
  belongs_to :fighter_feature_category

  validates :feature, presence: true
  validates :level, presence: true, inclusion: { in: 1..3 }

  scope :by_level, ->(level) { where(level: level) }
  scope :by_category, ->(category_id) { where(fighter_feature_category_id: category_id) }

  def level_text
    case level
    when 1
      '具体性が高い'
    when 2
      '普通' 
    when 3
      '抽象度が高い'
    end
  end

  def category_name
    fighter_feature_category.name
  end
end
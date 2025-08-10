class FighterFeatureCategory < ApplicationRecord
  has_many :fighter_features, dependent: :destroy

  validates :name, presence: true, uniqueness: true
end
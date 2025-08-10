class AddInitialFighterFeatureCategories < ActiveRecord::Migration[8.0]
  def up
    categories = %w[階級 戦績 来歴 通称 所属 ファイトスタイル その他]

    categories.each do |category_name|
      # Use Rails methods for database compatibility
      FighterFeatureCategory.find_or_create_by(name: category_name)
    end
  end

  def down
    categories = %w[階級 戦績 来歴 通称 所属 ファイトスタイル その他]
    FighterFeatureCategory.where(name: categories).destroy_all
  end
end

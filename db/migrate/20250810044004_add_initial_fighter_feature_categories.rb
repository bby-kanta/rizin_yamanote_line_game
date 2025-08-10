class AddInitialFighterFeatureCategories < ActiveRecord::Migration[8.0]
  def up
    categories = %w[階級 戦績 来歴 通称 所属 ファイトスタイル その他]

    categories.each do |category_name|
      execute "INSERT IGNORE INTO fighter_feature_categories (name, created_at, updated_at) VALUES ('#{category_name}', NOW(), NOW())"
    end
  end

  def down
    categories = %w[階級 戦績 来歴 通称 所属 ファイトスタイル その他]
    categories_list = categories.map { |name| "'#{name}'" }.join(', ')
    execute "DELETE FROM fighter_feature_categories WHERE name IN (#{categories_list})"
  end
end

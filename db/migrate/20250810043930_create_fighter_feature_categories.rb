class CreateFighterFeatureCategories < ActiveRecord::Migration[8.0]
  def change
    create_table :fighter_feature_categories do |t|
      t.string :name, null: false

      t.timestamps
    end

    add_index :fighter_feature_categories, :name, unique: true
  end
end

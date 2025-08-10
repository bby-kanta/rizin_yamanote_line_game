class CreateFighterFeatures < ActiveRecord::Migration[8.0]
  def change
    create_table :fighter_features do |t|
      t.references :fighter, null: false, foreign_key: true
      t.string :feature, null: false
      t.integer :level, null: false
      t.references :fighter_feature_category, null: false, foreign_key: true

      t.timestamps
    end

    add_index :fighter_features, [:fighter_id, :level]
    add_check_constraint :fighter_features, "level BETWEEN 1 AND 3", name: "level_range"
  end
end

class CreateFighterWeightClasses < ActiveRecord::Migration[8.0]
  def change
    create_table :fighter_weight_classes do |t|
      t.references :fighter, null: false, foreign_key: true
      t.references :weight_class, null: false, foreign_key: true

      t.timestamps
    end
    
    add_index :fighter_weight_classes, [:fighter_id, :weight_class_id], unique: true, name: 'index_fighter_weight_classes_on_fighter_and_weight_class'
  end
end

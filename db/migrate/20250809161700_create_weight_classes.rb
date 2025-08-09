class CreateWeightClasses < ActiveRecord::Migration[8.0]
  def change
    create_table :weight_classes do |t|
      t.string :japanese_name, null: false
      t.string :english_name, null: false

      t.timestamps
    end
    
    add_index :weight_classes, :japanese_name, unique: true
    add_index :weight_classes, :english_name, unique: true
  end
end

class CreateFighters < ActiveRecord::Migration[8.0]
  def change
    create_table :fighters do |t|
      t.string :full_name, null: false
      t.string :full_name_hiragana, null: false
      t.string :ring_name, null: true
      t.string :ring_name_hiraganam, null: true
      t.boolean :is_active, default: true, null: false

      t.timestamps
    end
    
    add_index :fighters, :full_name, unique: true
    add_index :fighters, :full_name_hiragana, unique: true
    add_index :fighters, :is_active
  end
end

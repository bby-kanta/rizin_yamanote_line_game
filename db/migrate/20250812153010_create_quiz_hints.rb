class CreateQuizHints < ActiveRecord::Migration[8.0]
  def change
    create_table :quiz_hints do |t|
      t.references :quiz_session, null: false, foreign_key: true
      t.references :fighter_feature, null: false, foreign_key: true
      t.integer :display_order, null: false

      t.timestamps
    end
    
    add_index :quiz_hints, [:quiz_session_id, :display_order], unique: true
    add_index :quiz_hints, [:quiz_session_id, :fighter_feature_id], unique: true
  end
end

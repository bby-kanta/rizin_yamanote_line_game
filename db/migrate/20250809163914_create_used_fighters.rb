class CreateUsedFighters < ActiveRecord::Migration[8.0]
  def change
    create_table :used_fighters do |t|
      t.references :game_session, null: false, foreign_key: true
      t.references :fighter, null: false, foreign_key: true
      t.references :used_by, null: false, foreign_key: { to_table: :users }
      t.datetime :used_at, null: false

      t.timestamps
    end
    
    add_index :used_fighters, [:game_session_id, :fighter_id], unique: true
  end
end

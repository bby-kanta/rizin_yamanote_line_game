class CreateGamePlayers < ActiveRecord::Migration[8.0]
  def change
    create_table :game_players do |t|
      t.references :game_session, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.integer :turn_order, null: false
      t.boolean :is_eliminated, null: false, default: false
      t.datetime :joined_at, null: false

      t.timestamps
    end
    
    add_index :game_players, [:game_session_id, :user_id], unique: true
    add_index :game_players, [:game_session_id, :turn_order], unique: true
  end
end

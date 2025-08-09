class CreateGameSessions < ActiveRecord::Migration[8.0]
  def change
    create_table :game_sessions do |t|
      t.string :name, null: false
      t.integer :status, null: false, default: 0
      t.references :creator, null: false, foreign_key: { to_table: :users }
      t.bigint :current_turn_player_id, null: true
      t.datetime :started_at
      t.datetime :ended_at

      t.timestamps
    end
    
    add_index :game_sessions, :status
    add_foreign_key :game_sessions, :users, column: :current_turn_player_id
  end
end

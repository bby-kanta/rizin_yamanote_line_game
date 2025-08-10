class AddWinnerUserIdToGameSessions < ActiveRecord::Migration[8.0]
  def change
    add_reference :game_sessions, :winner_user, null: true, foreign_key: { to_table: :users }
  end
end

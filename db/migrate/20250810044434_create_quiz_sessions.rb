class CreateQuizSessions < ActiveRecord::Migration[8.0]
  def change
    create_table :quiz_sessions do |t|
      t.references :creator, null: false, foreign_key: { to_table: :users }
      t.references :target_fighter, null: false, foreign_key: { to_table: :fighters }
      t.string :status, null: false, default: 'waiting'
      t.integer :current_hint_index, default: 0
      t.datetime :started_at
      t.datetime :ended_at
      t.references :winner_user, null: true, foreign_key: { to_table: :users }

      t.timestamps
    end
  end
end

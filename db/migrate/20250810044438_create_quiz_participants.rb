class CreateQuizParticipants < ActiveRecord::Migration[8.0]
  def change
    # create_table :quiz_participants do |t|
    #   t.references :quiz_session, null: false, foreign_key: true
    #   t.references :user, null: false, foreign_key: true
    #   t.integer :miss_count, default: 0
    #   t.datetime :answered_at
    #   t.integer :points, default: 0
    #   t.boolean :is_winner, default: false

    #   t.timestamps
    # end

    # add_index :quiz_participants, [:quiz_session_id, :user_id], unique: true
  end
end

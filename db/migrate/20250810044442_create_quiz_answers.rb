class CreateQuizAnswers < ActiveRecord::Migration[8.0]
  def change
    create_table :quiz_answers do |t|
      t.references :quiz_session, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.references :fighter, null: false, foreign_key: true
      t.boolean :is_correct, null: false
      t.datetime :submitted_at, null: false

      t.timestamps
    end

    add_index :quiz_answers, [:quiz_session_id, :user_id, :submitted_at]
  end
end

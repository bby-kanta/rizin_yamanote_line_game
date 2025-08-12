class AddUniqueIndexToQuizAnswers < ActiveRecord::Migration[8.0]
  def up
    add_index :quiz_answers, [:quiz_session_id, :user_id, :fighter_feature_id],
              unique: true, 
              name: 'index_quiz_answers_on_session_and_feature',
              where: 'fighter_feature_id IS NOT NULL'
  end
  
  def down
    remove_index :quiz_answers, name: 'index_quiz_answers_on_session_and_feature'
  end
end

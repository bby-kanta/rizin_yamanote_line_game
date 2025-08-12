class AddFighterFeatureIdToQuizAnswers < ActiveRecord::Migration[8.0]
  def change
    add_reference :quiz_answers, :fighter_feature, foreign_key: true, null: false
  end
end

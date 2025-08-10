class ChangeFighterIdToNullableInQuizAnswers < ActiveRecord::Migration[8.0]
  def change
    change_column_null :quiz_answers, :fighter_id, true
  end
end

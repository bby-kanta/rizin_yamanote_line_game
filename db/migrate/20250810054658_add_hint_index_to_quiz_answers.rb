class AddHintIndexToQuizAnswers < ActiveRecord::Migration[8.0]
  def change
    add_column :quiz_answers, :hint_index, :integer
  end
end

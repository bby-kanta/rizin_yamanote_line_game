class AddRespondedAtToQuizParticipants < ActiveRecord::Migration[8.0]
  def change
    add_column :quiz_participants, :responded_at, :datetime
  end
end

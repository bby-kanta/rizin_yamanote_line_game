class AddConnectionStatusToQuizParticipants < ActiveRecord::Migration[8.0]
  def change
    add_column :quiz_participants, :connected_at, :datetime
  end
end

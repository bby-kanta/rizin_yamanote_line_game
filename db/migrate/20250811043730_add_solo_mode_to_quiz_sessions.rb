class AddSoloModeToQuizSessions < ActiveRecord::Migration[8.0]
  def change
    add_column :quiz_sessions, :solo_mode, :boolean, default: false, null: false
  end
end

class AddEnglishFieldsToFighters < ActiveRecord::Migration[8.0]
  def change
    add_column :fighters, :full_name_english, :string
  end
end

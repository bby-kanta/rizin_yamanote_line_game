class AddImageUrlToFighters < ActiveRecord::Migration[8.0]
  def change
    add_column :fighters, :image_url, :string
  end
end

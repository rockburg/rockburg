class AddBackgroundToArtists < ActiveRecord::Migration[8.0]
  def change
    add_column :artists, :background, :text
  end
end

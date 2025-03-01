class AddRequiredLevelToArtists < ActiveRecord::Migration[8.0]
  def change
    add_column :artists, :required_level, :integer, default: 1, null: false
    add_index :artists, :required_level
  end
end

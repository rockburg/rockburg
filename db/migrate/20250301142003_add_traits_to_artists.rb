class AddTraitsToArtists < ActiveRecord::Migration[8.0]
  def change
    add_column :artists, :traits, :jsonb, default: {}, null: false
    add_index :artists, :traits, using: :gin
  end
end

class AddGenreAndTalentToVenues < ActiveRecord::Migration[8.0]
  def change
    add_column :venues, :genre, :string, null: false, default: "rock"
    add_column :venues, :talent, :integer, null: false, default: 50
  end
end

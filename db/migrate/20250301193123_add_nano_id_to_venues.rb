class AddNanoIdToVenues < ActiveRecord::Migration[8.0]
  def change
    add_column :venues, :nano_id, :string
    add_index :venues, :nano_id
  end
end

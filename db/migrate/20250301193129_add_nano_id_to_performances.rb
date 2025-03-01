class AddNanoIdToPerformances < ActiveRecord::Migration[8.0]
  def change
    add_column :performances, :nano_id, :string
    add_index :performances, :nano_id
  end
end

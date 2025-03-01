class AddNameToManagers < ActiveRecord::Migration[8.0]
  def change
    add_column :managers, :name, :string
  end
end

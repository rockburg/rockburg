class AddNanoIdToTables < ActiveRecord::Migration[8.0]
  def change
    # Add nano_id to artists table
    add_column :artists, :nano_id, :string
    add_index :artists, :nano_id, unique: true

    # Add nano_id to scheduled_actions table
    add_column :scheduled_actions, :nano_id, :string
    add_index :scheduled_actions, :nano_id, unique: true

    # Add nano_id to seasons table
    add_column :seasons, :nano_id, :string
    add_index :seasons, :nano_id, unique: true

    # Add nano_id to users table
    add_column :users, :nano_id, :string
    add_index :users, :nano_id, unique: true

    # Add nano_id to sessions table
    add_column :sessions, :nano_id, :string
    add_index :sessions, :nano_id, unique: true
  end
end

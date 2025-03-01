class PrepareArtistsForManagerOnly < ActiveRecord::Migration[8.0]
  def up
    # First fix any artists with null manager_id - give them a manager
    # Find artists with NULL manager_id
    execute <<-SQL
      UPDATE artists
      SET manager_id = (
        SELECT m.id FROM managers m
        JOIN users u ON m.user_id = u.id
        WHERE u.id = artists.user_id
        LIMIT 1
      )
      WHERE manager_id IS NULL AND user_id IS NOT NULL;
    SQL

    # For any remaining artists without a manager, we need to create a default manager
    execute <<-SQL
      WITH artists_without_managers AS (
        SELECT * FROM artists WHERE manager_id IS NULL
      ),
      default_manager AS (
        SELECT id FROM managers ORDER BY id LIMIT 1
      )
      UPDATE artists
      SET manager_id = (SELECT id FROM default_manager)
      WHERE id IN (SELECT id FROM artists_without_managers);
    SQL

    # Now we can make manager_id NOT NULL
    change_column_null :artists, :manager_id, false

    # Comment user_id to indicate it's deprecated, but keep it for now
    # in case there are any existing associations or code that depends on it
    change_column_comment :artists, :user_id, "DEPRECATED: This field will be removed. Use manager_id instead."

    # Add a note to the artists table to make it clear that manager is the primary association
    change_table_comment :artists, "Artists are primarily associated with managers, not users directly. The user_id field is deprecated."

    # Add an index and foreign key if they don't exist
    add_index :artists, :manager_id, if_not_exists: true
    add_foreign_key :artists, :managers, if_not_exists: true
  end

  def down
    # Make manager_id nullable again
    change_column_null :artists, :manager_id, true

    # Remove comments
    change_column_comment :artists, :user_id, nil
    change_table_comment :artists, nil
  end
end

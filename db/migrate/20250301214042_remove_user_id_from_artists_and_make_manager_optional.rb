class RemoveUserIdFromArtistsAndMakeManagerOptional < ActiveRecord::Migration[8.0]
  def up
    # Make manager_id optional for unsigned artists
    change_column_null :artists, :manager_id, true

    # Remove the user_id column from artists
    remove_column :artists, :user_id, :bigint

    # Update the table comment
    change_table_comment :artists, "Artists are associated with managers. Unsigned artists have no manager."
  end

  def down
    # Add user_id column back
    add_reference :artists, :user, null: true, index: true
    add_foreign_key :artists, :users

    # Restore the old table comment
    change_table_comment :artists, "Artists are primarily associated with managers, not users directly. The user_id field is deprecated."
  end
end

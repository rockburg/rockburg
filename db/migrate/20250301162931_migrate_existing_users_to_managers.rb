class MigrateExistingUsersToManagers < ActiveRecord::Migration[8.0]
  def up
    # Create a manager for each existing user
    User.find_each do |user|
      # Create a manager with default values
      manager = Manager.create!(
        user: user,
        budget: 1000.00,
        level: 1,
        xp: 0,
        skill_points: 5,
        traits: {},
        nano_id: SecureRandom.alphanumeric(10)
      )

      # Associate existing artists with the new manager
      user.artists.update_all(manager_id: manager.id)
    end

    # We're keeping manager_id optional to allow for unsigned artists
    # change_column_null :artists, :manager_id, false
  end

  def down
    # Migrate artists back to users
    Manager.find_each do |manager|
      manager.artists.update_all(user_id: manager.user_id)
    end

    # Delete all managers
    Manager.delete_all
  end
end

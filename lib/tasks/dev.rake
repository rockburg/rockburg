namespace :dev do
  desc "Reset the game to a new season (for development/testing only)"
  task reset: :environment do
    puts "Resetting game state..."

    # Get artist count from environment or default to 50
    artist_count = ENV.fetch("ARTIST_COUNT", "50").to_i

    # Always ensure diversity in artist traits and costs
    puts "Generating artists with wide diversity in traits and costs"

    ActiveRecord::Base.transaction do
      # 1. Set all seasons to inactive
      puts "Deactivating all seasons..."
      Season.update_all(active: false)

      # 2. Reset all managers to initial state
      puts "Resetting all managers..."
      Manager.all.each do |manager|
        manager.update!(
          budget: 1000.00,
          level: 1,
          xp: 0,
          skill_points: 0,
          traits: {}
        )
        # Clear all transactions for this manager
        manager.transactions.destroy_all
      end

      # 3. Clear all scheduled actions
      puts "Clearing all scheduled actions..."
      ScheduledAction.destroy_all

      # 4. Remove all existing artists
      puts "Removing all artists..."
      Artist.destroy_all

      # 5. Create a new season
      puts "Creating new season..."
      season = Season.create!(
        name: "Season #{Time.current.year}",
        active: true,
        settings: {
          "artist_count" => artist_count
        }
      )

      # 6. Generate artists for the new season
      puts "Queuing artist generation..."
      season.send(:generate_artists, artist_count)

      puts "Reset complete!"
      puts "Created new season: #{season.name} with #{season.settings['artist_count']} artists."
      puts "Artists are being generated in the background."
    end
  end

  desc "Regenerate artists without resetting the entire game state"
  task regenerate_artists: :environment do
    puts "Regenerating artists..."

    # Get count from argument or default to 50
    count = ENV.fetch("COUNT", "50").to_i

    # Always ensure diversity in artist traits and costs
    puts "Generating artists with wide diversity in traits and costs"

    # Remove all existing artists
    Artist.destroy_all

    # Clear all scheduled actions
    ScheduledAction.destroy_all

    # Generate new artists for current season
    current_season = Season.current

    if current_season
      puts "Generating #{count} artists for season: #{current_season.name}"

      # Use the existing generation method which now ensures diversity
      current_season.send(:generate_artists, count)

      puts "Artists are being generated in the background."
    else
      puts "Error: No active season found."
    end
  end
end

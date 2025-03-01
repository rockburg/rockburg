namespace :artists do
  desc "Regenerate signing costs for all artists"
  task regenerate_signing_costs: :environment do
    puts "Regenerating signing costs for all artists..."

    total_artists = Artist.count
    updated_count = 0

    Artist.find_each do |artist|
      # Skip artists without required_level (if any)
      next unless artist.required_level.present?

      # Calculate signing cost based on talent and required level
      base_cost = 1000
      talent_multiplier = (artist.talent / 10.0) + 0.5
      level_multiplier = artist.required_level * 0.5

      signing_cost = (base_cost * talent_multiplier * level_multiplier).round(2)

      # Update the artist with the calculated signing cost
      if artist.update_column(:signing_cost, signing_cost)
        updated_count += 1
        print "." if updated_count % 10 == 0
      end
    end

    puts "\nSuccessfully updated signing costs for #{updated_count}/#{total_artists} artists"
  end
end

require_relative "openai/venue_generator"

class VenueRegenerator
  def self.regenerate!(count: 25)
    ActiveRecord::Base.transaction do
      # Only regenerate venues that don't have any performances
      venues_with_performances = Venue.joins(:performances).distinct.pluck(:id)

      # Delete venues without performances
      if venues_with_performances.present?
        Venue.where.not(id: venues_with_performances).destroy_all
        puts "Keeping #{venues_with_performances.size} venues with performances."
      else
        # If no venues have performances, delete all venues
        Venue.destroy_all
        puts "No venues with performances found. Regenerating all venues."
      end

      begin
        # Initialize the venue generator
        venue_generator = OpenAI::VenueGenerator.new

        # Generate venues (default is 25 distributed across tiers)
        venue_data = venue_generator.generate_venues(count)

        # Create venues from the generated data
        venue_data.each do |venue_attributes|
          Venue.create!(venue_attributes)
        end

        puts "Created #{venue_data.size} new venues with GPT."
        true
      rescue => e
        puts "Error generating venues with GPT: #{e.message}"
        # Don't add fallback venues here, just report the error
        # Since this is called programmatically, we want to fail clearly
        false
      end
    end
  end
end

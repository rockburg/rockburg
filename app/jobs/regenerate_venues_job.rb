class RegenerateVenuesJob < ApplicationJob
  queue_as :default

  def perform(venue_count = 25)
    Rails.logger.info "Starting venue regeneration job with count: #{venue_count}"

    # Call the venue regenerator service
    success = VenueRegenerator.regenerate!(count: venue_count)

    if success
      Rails.logger.info "Successfully regenerated venues with count: #{venue_count}"

      # Update venue stats for the active season
      VenueStatsService.after_venue_regeneration
    else
      Rails.logger.error "Failed to regenerate venues"
    end
  end
end

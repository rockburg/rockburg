class GenerateArtistsJob < ApplicationJob
  queue_as :default

  def perform(season_id, count)
    season = Season.find_by(id: season_id)
    return unless season

    Rails.logger.info "Starting artist generation job for Season ##{season_id} (#{count} artists)"

    # Generate artists in batches of 5 to avoid overwhelming the API
    batch_size = 5
    remaining = count

    while remaining > 0
      current_batch = [ batch_size, remaining ].min
      Rails.logger.info "Generating batch of #{current_batch} artists"

      begin
        ArtistGeneratorService.generate_batch(current_batch, User.first)
        Rails.logger.info "Successfully generated batch of #{current_batch} artists"
      rescue => e
        Rails.logger.error "Error generating artists batch: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
      end

      remaining -= current_batch

      # Add a small delay between batches to avoid rate limiting
      sleep(2) if remaining > 0
    end

    Rails.logger.info "Completed artist generation job for Season ##{season_id}"
  end
end

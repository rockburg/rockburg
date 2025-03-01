class GenerateArtistsJob < ApplicationJob
  queue_as :default

  def perform(season_id, count)
    season = Season.find_by(id: season_id)
    return unless season

    Rails.logger.info "Starting artist generation job for Season ##{season_id} (#{count} artists)"

    # Generate artists in batches of 20 to ensure better distribution of traits
    batch_size = 20
    remaining = count
    total_created = 0
    total_failed = 0

    while remaining > 0
      current_batch = [ batch_size, remaining ].min
      Rails.logger.info "Generating batch of #{current_batch} artists"

      begin
        artists = ArtistGeneratorService.generate_batch(current_batch, User.first)
        successful_count = artists.length
        failed_count = current_batch - successful_count

        total_created += successful_count
        total_failed += failed_count

        Rails.logger.info "Successfully generated #{successful_count}/#{current_batch} artists in this batch"

        if failed_count > 0
          Rails.logger.warn "Failed to generate #{failed_count} artists in this batch"
        end

        # Verify the artists were actually saved to the database
        artist_ids = artists.map(&:id)
        saved_count = Artist.where(id: artist_ids).count

        if saved_count != successful_count
          Rails.logger.error "Database inconsistency detected: #{successful_count} artists created but only #{saved_count} found in database"
        else
          Rails.logger.info "Verified all #{successful_count} artists are in the database"
        end
      rescue => e
        Rails.logger.error "Error generating artists batch: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
        total_failed += current_batch
      end

      remaining -= current_batch

      # Add a small delay between batches to avoid rate limiting
      sleep(2) if remaining > 0
    end

    Rails.logger.info "Completed artist generation job for Season ##{season_id}"
    Rails.logger.info "Total artists created: #{total_created}/#{count} (#{total_failed} failed)"

    # Final database verification
    recent_artists = Artist.where("created_at >= ?", 10.minutes.ago).count
    Rails.logger.info "Recent artists created in database (last 10 min): #{recent_artists}"
  end
end

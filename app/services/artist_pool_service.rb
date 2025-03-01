class ArtistPoolService
  MIN_AVAILABLE_ARTISTS = 10

  def self.ensure_minimum_artists_available
    available_count = Artist.where(manager_id: nil).count

    if available_count < MIN_AVAILABLE_ARTISTS
      count_to_generate = MIN_AVAILABLE_ARTISTS - available_count
      Rails.logger.info "Generating #{count_to_generate} artists to maintain minimum pool size"

      begin
        ArtistGeneratorService.generate_batch(count_to_generate)
      rescue => e
        Rails.logger.error "Error generating artists for pool: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
      end
    end
  end
end

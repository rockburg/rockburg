class MaintainArtistPoolJob < ApplicationJob
  queue_as :default

  def perform
    ArtistPoolService.ensure_minimum_artists_available
  end
end

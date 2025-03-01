class VenuesController < ApplicationController
  before_action :require_current_user
  before_action :set_venue, only: [ :show ]

  def index
    # Get all venues, organized by tier
    @venues_by_tier = {}

    # Group venues by tier
    (1..5).each do |tier|
      @venues_by_tier[tier] = Venue.by_tier(tier).order(capacity: :desc)
    end

    # Get available venues for the current manager
    @available_venues = Current.user.manager.available_venues if Current.user.manager
  end

  def show
    # Check if there are any past performances at this venue by the manager's artists
    @past_performances = @venue.performances
                               .joins(:artist)
                               .where(artists: { manager_id: Current.user.manager.id })
                               .where(status: "completed")
                               .order(scheduled_for: :desc)
                               .limit(5)

    # Get available artists that could perform at this venue
    @available_artists = Current.user.manager.artists.select do |artist|
      Venue.available_for_artist(artist).include?(@venue)
    end
  end

  private

  def set_venue
    @venue = find_resource(Venue)
  end
end

class ArtistSelectionsController < ApplicationController
  def index
    # Ensure there are artists available for selection
    # ArtistPoolService.ensure_minimum_artists_available

    # Get unassigned artists (artists not belonging to any user)
    @artists = Artist.where(user_id: nil).order(created_at: :desc).limit(30)
  end

  def select
    @artist = Artist.find(params[:id])

    if @artist.user.present?
      redirect_to artists_path, alert: "This artist has already been selected by another player."
      return
    end

    # Assign the artist to the current user
    @artist.update!(user: Current.user)
    redirect_to artist_path(@artist), notice: "You've successfully signed #{@artist.name} to your label!"
  end
end

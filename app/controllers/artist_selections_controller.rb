class ArtistSelectionsController < ApplicationController
  include ActionView::Helpers::NumberHelper

  def index
    # Ensure there are artists available for selection
    # ArtistPoolService.ensure_minimum_artists_available

    # Get unassigned artists (artists not belonging to any user)
    @artists = Artist.where(user_id: nil, manager_id: nil).order(created_at: :desc).limit(30)
  end

  def select
    @artist = find_resource(Artist)
    @manager = Current.user.ensure_manager

    # Check if artist is already signed
    if @artist.signed?
      redirect_to artists_path, alert: "This artist has already been signed by another manager."
      return
    end

    # Check if manager meets level requirements
    unless @artist.eligible_for?(@manager)
      redirect_to artists_path, alert: "Your manager level is too low to sign this artist. You need to be level #{@artist.required_level} or higher."
      return
    end

    # Check if manager can afford the signing cost
    unless @artist.affordable_for?(@manager)
      redirect_to artists_path, alert: "You don't have enough funds to sign this artist. You need #{number_to_currency(@artist.signing_cost)}."
      return
    end

    # Sign the artist using the manager's sign_artist method
    if @manager.sign_artist(@artist)
      redirect_to artist_path(@artist), notice: "You've successfully signed #{@artist.name} to your label for #{number_to_currency(@artist.signing_cost)}!"
    else
      redirect_to artists_path, alert: "There was an error signing this artist. Please try again."
    end
  end
end

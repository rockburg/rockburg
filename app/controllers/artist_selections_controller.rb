class ArtistSelectionsController < ApplicationController
  include ActionView::Helpers::NumberHelper
  before_action :require_current_user

  def index
    @artists = Artist.all

    if params[:affordable].present?
      @artists = @artists.select { |artist| artist.affordable_for?(Current.user.manager) }
    end

    if params[:eligible].present?
      @artists = @artists.select { |artist| artist.eligible_for?(Current.user.manager) }
    end

    if params[:genre].present?
      # Use case-insensitive partial matching for genre search
      # This will match any genre that contains the search term
      # e.g., "rock" will match "Indie Rock", "Rock and Roll", "Garage Rock", etc.
      genre_query = params[:genre].downcase
      @artists = @artists.select { |artist| artist.genre.downcase.include?(genre_query) }
    end

    case params[:sort]
    when "cost"
      @artists = @artists.sort_by(&:signing_cost)
    when "level"
      @artists = @artists.sort_by(&:required_level)
    when "talent"
      @artists = @artists.sort_by(&:talent).reverse
    end
  end

  def select
    artist = Artist.find_by_nano_id(params[:id])

    raise ActiveRecord::RecordNotFound, "Couldn't find Artist with nano_id=#{params[:id]}" unless artist

    if artist.manager.present?
      redirect_to artists_path, alert: "This artist has already been signed."
    else
      # Use the sign_artist method to properly deduct funds
      if Current.user.manager.sign_artist(artist)
        redirect_to artist_path(artist), notice: "Artist successfully signed!"
      else
        # Get specific error reason
        if !Current.user.manager.can_afford?(artist.signing_cost)
          message = "You cannot afford to sign this artist."
        elsif Current.user.manager.level < artist.required_level
          message = "Your manager level is too low to sign this artist."
        else
          message = "Unable to sign this artist."
        end

        redirect_to artist_selections_path, alert: message
      end
    end
  end
end

class ArtistsController < ApplicationController
  before_action :set_artist, only: [ :show, :edit, :update, :destroy, :perform_activity ]
  before_action :ensure_owner, only: [ :edit, :update, :destroy, :perform_activity ]

  def index
    @artists = Current.user.artists
  end

  def show
  end

  def new
    @artist = Artist.new
  end

  def create
    @artist = Current.user.artists.build(artist_params)
    process_traits_params

    if @artist.save
      redirect_to @artist, notice: "Artist was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @artist.update(artist_params)
      process_traits_params
      @artist.save
      redirect_to @artist, notice: "Artist was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @artist.destroy
    redirect_to artists_path, notice: "Artist was successfully deleted."
  end

  def perform_activity
    activity = params[:activity]

    if @artist.perform_activity!(activity)
      redirect_to @artist, notice: "#{activity.capitalize} activity completed successfully."
    else
      redirect_to @artist, alert: "Not enough energy to perform #{activity}."
    end
  rescue ArgumentError => e
    redirect_to @artist, alert: e.message
  end

  private

  def set_artist
    @artist = Artist.find(params[:id])
  end

  def ensure_owner
    unless @artist.user == Current.user
      redirect_to artists_path, alert: "You don't have permission to perform this action."
    end
  end

  def artist_params
    params.require(:artist).permit(:name, :genre, :energy, :talent)
  end

  def process_traits_params
    # Initialize traits as an empty hash if it doesn't exist
    @artist.traits ||= {}

    # Process each trait from the params
    [ :charisma, :creativity, :resilience, :discipline ].each do |trait|
      if params[:artist][trait].present?
        @artist.traits[trait.to_s] = params[:artist][trait].to_i
      end
    end
  end
end

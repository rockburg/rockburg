class Admin::SeasonsController < ApplicationController
  include AdminAuthentication
  before_action :set_season, only: [ :show, :edit, :update, :destroy, :generate_artists ]

  def index
    @seasons = Season.all.order(created_at: :desc)
  end

  def show
  end

  def new
    @season = Season.new
  end

  def edit
  end

  def create
    @season = Season.new(season_params)

    # Process artist_count parameter
    process_artist_count

    if @season.save
      redirect_to admin_season_path(@season), notice: "Season was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    # Process artist_count parameter
    process_artist_count

    if @season.update(season_params)
      redirect_to admin_season_path(@season), notice: "Season was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @season.destroy
    redirect_to admin_seasons_path, notice: "Season was successfully destroyed."
  end

  # Manually trigger artist generation
  def generate_artists
    count = params[:count].to_i

    if count > 0 && count <= 1000
      @season.send(:generate_artists, count)
      redirect_to admin_season_path(@season), notice: "Started generating #{count} artists. This may take some time."
    else
      redirect_to admin_season_path(@season), alert: "Please specify a valid number of artists (1-1000)."
    end
  end

  private

  def set_season
    @season = find_resource(Season)
  end

  def process_artist_count
    if params[:season][:artist_count].present?
      # Initialize settings as empty hash if nil
      @season.settings ||= {}

      # Convert to hash if it's a JSON string
      @season.settings = JSON.parse(@season.settings) if @season.settings.is_a?(String)

      # Store artist_count in settings
      @season.settings = @season.settings.merge("artist_count" => params[:season][:artist_count].to_i)
    end
  end

  def season_params
    params.require(:season).permit(:name, :description, :active, :started_at, :ended_at, :transition_ends_at, :settings, :genre_trends)
  end
end

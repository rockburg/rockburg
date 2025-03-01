class ArtistsController < ApplicationController
  before_action :set_artist, only: [ :show, :edit, :update, :perform_activity, :cancel_activity, :schedule_activity, :cancel_scheduled_activity ]
  before_action :ensure_owner, only: [ :perform_activity, :cancel_activity, :schedule_activity, :cancel_scheduled_activity ]

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
    redirect_to @artist, alert: "Editing artists is not permitted."
  end

  def update
    redirect_to @artist, alert: "Editing artists is not permitted."
  end

  def perform_activity
    activity = params[:activity]

    if @artist.busy?
      redirect_to @artist, alert: "This artist is already performing an action."
      return
    end

    if @artist.start_activity!(activity)
      redirect_to @artist, notice: "#{activity.capitalize} activity started. It will complete in #{@artist.formatted_time_remaining}."
    else
      redirect_to @artist, alert: "Not enough energy to perform #{activity}."
    end
  rescue ArgumentError => e
    redirect_to @artist, alert: e.message
  end

  def cancel_activity
    if @artist.busy?
      # Clear the action status
      @artist.update(current_action: nil, action_started_at: nil, action_ends_at: nil)
      redirect_to @artist, notice: "Activity canceled."
    else
      redirect_to @artist, alert: "No active activity to cancel."
    end
  end

  def schedule_activity
    activity = params[:activity]
    start_time = Time.zone.parse(params[:start_time])

    begin
      scheduled_action = @artist.schedule_activity!(activity, start_time)
      redirect_to @artist, notice: "#{activity.capitalize} scheduled for #{start_time.strftime('%B %d at %I:%M %p')}."
    rescue ArgumentError => e
      redirect_to @artist, alert: e.message
    rescue ActiveRecord::RecordInvalid => e
      redirect_to @artist, alert: e.record.errors.full_messages.to_sentence
    end
  end

  def cancel_scheduled_activity
    scheduled_action_id = params[:scheduled_action_id]

    begin
      @artist.cancel_scheduled_action!(scheduled_action_id)
      redirect_to @artist, notice: "Scheduled activity canceled."
    rescue ActiveRecord::RecordNotFound
      redirect_to @artist, alert: "Scheduled activity not found."
    end
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

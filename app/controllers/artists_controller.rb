class ArtistsController < ApplicationController
  before_action :set_artist, only: [ :show, :edit, :update, :perform_activity, :cancel_activity, :schedule_activity, :cancel_scheduled_activity, :sign ]
  before_action :ensure_owner, only: [ :perform_activity, :cancel_activity, :schedule_activity, :cancel_scheduled_activity ]
  before_action :require_current_user, only: [ :sign ]
  before_action :require_current_manager, only: [ :index ]

  def index
    @artists = current_manager.artists
  end

  def show
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

  def sign
    # Check if the artist is already signed
    if @artist.signed?
      redirect_to @artist, alert: "This artist is already signed."
      return
    end

    # Check if the current user has a manager
    unless Current.user&.manager
      redirect_to @artist, alert: "You need to create a manager first."
      return
    end

    # Attempt to sign the artist
    if current_manager.sign_artist(@artist)
      redirect_to @artist, notice: "You have successfully signed #{@artist.name}!"
    else
      # Get specific error reason
      if !current_manager.can_afford?(@artist.signing_cost)
        message = "You cannot afford to sign this artist."
      elsif current_manager.level < @artist.required_level
        message = "Your manager level is too low to sign this artist."
      else
        message = "Unable to sign this artist."
      end

      redirect_to @artist, alert: message
    end
  end

  private

  def set_artist
    @artist = find_resource(Artist)
  end

  def ensure_owner
    # Check ownership through the manager association
    unless @artist&.manager && @artist.manager == current_manager
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

  def require_current_user
    unless Current.user
      redirect_to new_session_path, alert: "You must be logged in to perform this action."
    end
  end
end

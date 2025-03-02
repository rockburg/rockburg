class PerformancesController < ApplicationController
  include ActionView::Helpers::NumberHelper
  before_action :require_current_user
  before_action :require_current_manager
  before_action :set_performance, only: [ :show, :cancel, :complete ]
  before_action :ensure_owner, only: [ :cancel, :complete ]

  def index
    @upcoming_performances = current_manager.upcoming_performances
    @past_performances = current_manager.past_performances.limit(10)
    @artists = current_manager.artists
  end

  def show
    @venue = @performance.venue
    @artist = @performance.artist
    @estimated_revenue = @performance.estimate_revenue if @performance.status == "scheduled"
  end

  def new
    @artist = find_resource(Artist, :artist_id)

    # Check if the artist is managed by the current manager
    unless @artist&.manager && @artist.manager == current_manager
      redirect_to artists_path, alert: "You don't manage this artist." and return
    end

    @venues = current_manager.available_venues
    @performance = Performance.new(artist: @artist)
  end

  def create
    @artist = find_resource(Artist, :artist_id)

    # Check if the artist is managed by the current manager
    unless @artist&.manager && @artist.manager == current_manager
      redirect_to artists_path, alert: "You don't manage this artist." and return
    end

    @venue = Venue.find_by_id_or_nano_id(params[:performance][:venue_id])

    # Check if the venue exists
    unless @venue.present?
      @venues = current_manager.available_venues
      @performance = Performance.new(artist: @artist)
      flash.now[:alert] = "The selected venue could not be found."
      return render :new, status: :unprocessable_entity
    end

    scheduled_for = Time.zone.parse(params[:performance][:scheduled_for])
    ticket_price = params[:performance][:ticket_price].to_f

    @performance = @artist.book_performance(@venue, scheduled_for, ticket_price)

    if @performance.persisted?
      redirect_to @performance, notice: "Performance booked successfully! You've been charged a booking fee of #{number_to_currency(@venue.booking_cost)}."
    else
      @venues = current_manager.available_venues
      render :new, status: :unprocessable_entity
    end
  end

  def cancel
    if @performance.cancel!
      redirect_to performances_path, notice: "Performance cancelled successfully."
    else
      redirect_to @performance, alert: "Unable to cancel this performance."
    end
  end

  def complete
    if @performance.complete!
      revenue = number_to_currency(@performance.net_revenue)
      attendees = @performance.attendance

      # Check for level up
      level_up_message = current_manager.check_level_up

      if level_up_message
        redirect_to @performance, notice: "Performance completed successfully with #{attendees} attendees and #{revenue} in revenue! #{level_up_message}"
      else
        redirect_to @performance, notice: "Performance completed successfully with #{attendees} attendees and #{revenue} in revenue!"
      end
    else
      redirect_to @performance, alert: "Unable to complete this performance."
    end
  end

  private

  def set_performance
    @performance = find_resource(Performance)
  end

  def ensure_owner
    unless @performance&.artist&.manager && @performance.artist.manager == current_manager
      redirect_to performances_path, alert: "You don't manage the artist for this performance."
    end
  end
end

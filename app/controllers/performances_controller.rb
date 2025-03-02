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

    # Get venues available for this artist
    @venues = current_manager.available_venues
    
    # Check if the artist has enough energy to perform
    if !@artist.can_perform?
      flash.now[:alert] = "Your artist doesn't have enough energy to perform. They need at least 20 energy."
    end
    
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

    # Check if the artist has enough energy
    unless @artist.can_perform?
      @venues = current_manager.available_venues
      @performance = Performance.new(artist: @artist)
      flash.now[:alert] = "Your artist doesn't have enough energy to perform. They need at least 20 energy."
      return render :new, status: :unprocessable_entity
    end

    scheduled_for = Time.zone.parse(params[:performance][:scheduled_for])
    ticket_price = params[:performance][:ticket_price].to_f
    duration_minutes = params[:performance][:duration_minutes].to_i

    # Check if the scheduled date is valid
    if scheduled_for < 24.hours.from_now
      @venues = current_manager.available_venues
      @performance = Performance.new(artist: @artist)
      flash.now[:alert] = "Performance must be scheduled at least 24 hours in advance."
      return render :new, status: :unprocessable_entity
    end

    # Check if the manager can afford the booking cost
    unless @artist.manager.can_afford?(@venue.booking_cost)
      @venues = current_manager.available_venues
      @performance = Performance.new(artist: @artist)
      flash.now[:alert] = "You don't have enough funds to book this venue. It costs #{number_to_currency(@venue.booking_cost)}."
      return render :new, status: :unprocessable_entity
    end

    @performance = @artist.book_performance(@venue, scheduled_for, ticket_price, { duration_minutes: duration_minutes })

    if @performance.persisted?
      # Calculate estimated revenue for success message
      estimated_revenue = @venue.estimate_revenue(@artist.popularity, ticket_price)
      
      redirect_to @performance, notice: "Performance booked successfully! You've been charged a booking fee of #{number_to_currency(@venue.booking_cost)}. Estimated attendance: #{estimated_revenue[:attendance]} people."
    else
      @venues = current_manager.available_venues
      flash.now[:alert] = "There was a problem booking the performance."
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

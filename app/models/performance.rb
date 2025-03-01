class Performance < ApplicationRecord
  include HasNanoId

  belongs_to :artist
  belongs_to :venue

  # Status values
  STATUSES = %w[scheduled in_progress completed cancelled failed].freeze

  # Validations
  validates :scheduled_for, presence: true
  validates :duration_minutes, presence: true, numericality: { greater_than: 0 }
  validates :ticket_price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :status, presence: true, inclusion: { in: STATUSES }

  # Scopes
  scope :upcoming, -> { where(status: "scheduled").where("scheduled_for > ?", Time.current) }
  scope :past, -> { where(status: [ "completed", "cancelled", "failed" ]) }
  scope :active, -> { where(status: [ "scheduled", "in_progress" ]) }
  scope :successful, -> { where(status: "completed") }
  scope :by_artist, ->(artist) { where(artist: artist) }
  scope :for_manager, ->(manager) { joins(:artist).where(artists: { manager_id: manager.id }) }

  # Book a performance for an artist at a venue
  def self.book(artist, venue, scheduled_for, ticket_price, details = {})
    # Ensure the artist has a manager
    return false unless artist.manager.present?

    # Check if the venue is available for the artist based on level
    return false unless venue.class.available_for_artist(artist).include?(venue)

    # Check if the artist can afford the booking cost
    return false unless artist.manager.can_afford?(venue.booking_cost)

    # Check if the scheduled date is in the future
    return false unless scheduled_for > Time.current

    # Validate minimum ticket price
    minimum_price = venue.minimum_ticket_price
    if ticket_price < minimum_price
      ticket_price = minimum_price
    end

    # Create the performance
    performance = create(
      artist: artist,
      venue: venue,
      scheduled_for: scheduled_for,
      duration_minutes: details[:duration_minutes] || 60,
      ticket_price: ticket_price,
      status: "scheduled",
      details: details
    )

    # Charge the booking fee to the artist's manager
    if performance.persisted?
      artist.manager.deduct_funds(
        venue.booking_cost,
        "Booking fee for performance at #{venue.name}",
        artist
      )
    end

    performance
  end

  # Complete a performance and calculate revenue
  def complete!
    return false unless status == "scheduled" || status == "in_progress"
    return false unless scheduled_for <= Time.current

    # Set to in_progress first if needed
    update(status: "in_progress") if status == "scheduled"

    # Calculate attendance and revenue
    actual_attendance = calculate_attendance
    calculate_revenue(actual_attendance)

    # Calculate gains for the artist
    calculate_artist_benefits

    # Update artist stats
    update_artist

    # Pay the artist's manager
    distribute_revenue

    # Mark as completed
    update(status: "completed")
    true
  end

  # Cancel a performance
  def cancel!
    return false unless status == "scheduled"

    # If cancelled more than 7 days before, refund 50% of booking cost
    if scheduled_for > 7.days.from_now
      refund_amount = venue.booking_cost * 0.5
      artist.manager.add_funds(
        refund_amount,
        "Partial refund for cancelled performance at #{venue.name}",
        artist
      )
    end

    update(status: "cancelled")
    true
  end

  # Calculate the attendance for this performance
  def calculate_attendance
    # Start with the estimated attendance
    estimated = venue.estimate_attendance(artist, ticket_price)

    # Add some randomness for actual performance
    performance_factor = 0.8 + (rand * 0.4) # 0.8 to 1.2

    # Factor in artist energy level (fatigued artists draw smaller crowds)
    energy_ratio = artist.energy / artist.max_energy.to_f
    energy_factor = 0.5 + (energy_ratio * 0.5) # 0.5 to 1.0

    # Calculate final attendance
    final_attendance = (estimated * performance_factor * energy_factor).round

    # Cap at venue capacity
    [ final_attendance, venue.capacity ].min
  end

  # Calculate revenue for this performance
  def calculate_revenue(attendance)
    # Update the attendance record
    self.attendance = attendance

    # Calculate gross revenue from ticket sales
    self.gross_revenue = attendance * ticket_price

    # Calculate venue's cut
    venue_percentage = 0.15 + (venue.tier * 0.05)
    self.venue_cut = gross_revenue * venue_percentage

    # Calculate expenses
    self.expenses = venue.booking_cost + (attendance * 2) # $2 per attendee for misc costs

    # Calculate merchandise revenue
    merch_per_attendee = 5 + (venue.tier * 2)
    merch_take_rate = 0.2 # 20% of attendees buy merch
    self.merch_revenue = attendance * merch_take_rate * merch_per_attendee

    # Calculate net revenue
    self.net_revenue = gross_revenue - venue_cut - expenses + merch_revenue

    save
  end

  # Calculate skill and popularity gains for the artist
  def calculate_artist_benefits
    # Base XP gain
    base_xp = 10 * venue.prestige

    # Attendance ratio affects gains
    attendance_ratio = attendance.to_f / venue.capacity
    attendance_factor = 0.5 + (attendance_ratio * 0.5) # 0.5 to 1.0

    # Calculate skill gain
    base_skill_gain = 2 + venue.prestige
    self.skill_gain = (base_skill_gain * attendance_factor).round

    # Calculate popularity gain
    base_popularity_gain = 3 + (venue.prestige * 2)
    self.popularity_gain = (base_popularity_gain * attendance_factor).round

    save
  end

  # Update the artist with the gains from this performance
  def update_artist
    # Update skill
    artist.skill += skill_gain

    # Update popularity
    artist.popularity += popularity_gain

    # Decrease energy from performance (performing is tiring)
    energy_cost = 20 + (duration_minutes / 15)
    artist.energy = [ artist.energy - energy_cost, 0 ].max

    artist.save
  end

  # Pay the artist's manager the revenue from this performance
  def distribute_revenue
    return false unless status == "in_progress" && net_revenue > 0

    artist.manager.add_funds(
      net_revenue,
      "Revenue from performance at #{venue.name} (#{attendance} attendees)",
      artist
    )

    true
  end

  # Check if a performance is currently happening
  def in_progress?
    scheduled_for <= Time.current &&
    scheduled_for + duration_minutes.minutes >= Time.current &&
    status == "scheduled"
  end

  # Check if a performance is completed
  def completed?
    status == "completed"
  end

  # Check if a performance is cancelled
  def cancelled?
    status == "cancelled"
  end

  # Check if a performance is scheduled
  def scheduled?
    status == "scheduled"
  end

  # Get the estimated revenue before a performance
  def estimate_revenue
    venue.estimate_revenue(artist, ticket_price)
  end
end

class Venue < ApplicationRecord
  include HasNanoId

  has_many :performances, dependent: :restrict_with_error

  validates :name, presence: true
  validates :capacity, presence: true, numericality: { greater_than: 0 }
  validates :booking_cost, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :prestige, presence: true, numericality: { greater_than_or_equal_to: 1, less_than_or_equal_to: 10 }
  validates :tier, presence: true, numericality: { greater_than_or_equal_to: 1, less_than_or_equal_to: 5 }
  validates :genre, presence: true
  validates :talent, presence: true, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }

  # Scopes
  scope :by_tier, ->(tier) { where(tier: tier) }
  scope :available_for_artist_level, ->(level) { where("tier <= ?", [ (level / 20.0).ceil, 5 ].min) }

  # Returns venues that an artist of given level can book
  def self.available_for_artist(artist)
    if artist.manager.present?
      available_for_artist_level(artist.manager.level)
    else
      none
    end
  end

  # Calculate minimum ticket price based on venue's tier and booking cost
  def minimum_ticket_price
    (booking_cost / (capacity * 0.5)).ceil
  end

  # Calculate suggested ticket price for maximum revenue
  def suggested_ticket_price(artist_popularity = 1)
    base_price = minimum_ticket_price
    popularity_factor = [ artist_popularity, 1 ].max / 100.0
    tier_factor = tier * 0.5

    (base_price * (1 + popularity_factor + tier_factor)).ceil
  end

  # Estimate attendance based on artist, ticket price, and other factors
  def estimate_attendance(artist_popularity, ticket_price)
    # Get artist popularity as a number
    popularity = artist_popularity.is_a?(Artist) ? artist_popularity.popularity : artist_popularity.to_i

    # Base attendance as a percentage of capacity
    base_percentage = 0.3 + (popularity / 100.0 * 0.5)

    # Price sensitivity - higher prices reduce attendance
    suggested = suggested_ticket_price(popularity)
    price_factor = if ticket_price <= suggested
                     1.0
    else
                     # Attendance drops as price exceeds suggested price
                     1.0 - [ (ticket_price - suggested) / suggested * 0.5, 0.9 ].min
    end

    # Calculate attendance
    attendance = (capacity * base_percentage * price_factor).round

    # Ensure attendance is within bounds
    [ attendance, capacity ].min
  end

  # Calculate estimated revenue for a performance
  def estimate_revenue(artist_popularity, ticket_price)
    # Get artist popularity as a number
    popularity = artist_popularity.is_a?(Artist) ? artist_popularity.popularity : artist_popularity.to_i

    attendance = estimate_attendance(popularity, ticket_price)

    # Calculate revenue components
    gross_revenue = attendance * ticket_price
    venue_cut = gross_revenue * 0.2 # Venue takes 20%
    expenses = booking_cost + (attendance * 2) # Fixed cost + $2 per attendee for staff, etc.
    merch_revenue = attendance * 5 * (popularity / 100.0) # $5 per attendee scaled by popularity
    net_revenue = gross_revenue - venue_cut - expenses + merch_revenue

    {
      attendance: attendance,
      gross_revenue: gross_revenue,
      venue_cut: venue_cut,
      expenses: expenses,
      merch_revenue: merch_revenue,
      net_revenue: net_revenue
    }
  end
end

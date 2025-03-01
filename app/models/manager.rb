class Manager < ApplicationRecord
  include HasNanoId

  belongs_to :user
  has_many :artists, dependent: :nullify
  has_many :transactions, dependent: :destroy

  validates :budget, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :level, presence: true, numericality: { greater_than_or_equal_to: 1 }
  validates :xp, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :skill_points, presence: true, numericality: { greater_than_or_equal_to: 0 }

  # XP required for each level
  LEVEL_XP_REQUIREMENTS = {
    1 => 0,
    2 => 1000,
    3 => 3000,
    4 => 7000,
    5 => 15000,
    6 => 30000,
    7 => 60000,
    8 => 100000,
    9 => 175000,
    10 => 300000
  }.freeze

  # Alias for budget to maintain consistent naming with transactions
  def balance
    budget
  end

  # Check if manager can afford a cost
  def can_afford?(amount)
    budget >= amount
  end

  # Add funds to the manager's budget
  def add_funds(amount, description, artist = nil)
    return false if amount <= 0

    transaction do
      self.budget += amount
      save!

      transactions.create!(
        amount: amount,
        description: description,
        transaction_type: "income",
        artist: artist,
        nano_id: SecureRandom.alphanumeric(10)
      )
    end

    true
  end

  # Deduct funds from the manager's budget
  def deduct_funds(amount, description, artist = nil)
    return false if amount <= 0 || !can_afford?(amount)

    transaction do
      self.budget -= amount
      save!

      transactions.create!(
        amount: -amount,
        description: description,
        transaction_type: "expense",
        artist: artist,
        nano_id: SecureRandom.alphanumeric(10)
      )
    end

    true
  end

  # Check if manager can sign an artist
  def can_sign_artist?(artist)
    return false unless artist

    # Check if manager has enough funds for signing cost
    return false unless can_afford?(artist.signing_cost)

    # Check if manager has required level
    level >= artist.required_level
  end

  # Sign an artist
  def sign_artist(artist)
    return false unless can_sign_artist?(artist)

    transaction do
      # Deduct signing cost
      deduct_funds(artist.signing_cost, "Signed artist: #{artist.name}", artist)

      # Associate artist with manager
      artist.update!(manager: self, user: user)
    end

    true
  end

  # Add XP to manager
  def add_xp(amount)
    return false if amount <= 0

    transaction do
      self.xp += amount
      check_level_up
      save!
    end

    true
  end

  # Check if manager should level up
  def check_level_up
    next_level = level + 1

    # Cap at level 10
    return if level >= 10

    # Check if we have enough XP for the next level
    if LEVEL_XP_REQUIREMENTS.key?(next_level) && xp >= LEVEL_XP_REQUIREMENTS[next_level]
      self.level = next_level
      self.skill_points += 3 # Award skill points for leveling up
    end
  end

  # Get XP required for next level
  def xp_for_next_level
    next_level = level + 1
    return nil if next_level > 10

    LEVEL_XP_REQUIREMENTS[next_level]
  end

  # Calculate XP progress percentage to next level
  def xp_progress_percentage
    next_level_xp = xp_for_next_level
    return 100 if next_level_xp.nil? # Already at max level

    current_level_xp = LEVEL_XP_REQUIREMENTS[level]
    xp_needed = next_level_xp - current_level_xp
    xp_gained = xp - current_level_xp

    [ (xp_gained.to_f / xp_needed * 100).to_i, 100 ].min
  end

  # Get all upcoming performances for this manager's artists
  def upcoming_performances
    Performance.for_manager(self).upcoming.order(scheduled_for: :asc)
  end

  # Get all past performances for this manager's artists
  def past_performances
    Performance.for_manager(self).past.order(scheduled_for: :desc)
  end

  # Get total earnings from performances for all artists
  def total_performance_earnings
    Performance.for_manager(self).successful.sum(:net_revenue)
  end

  # Get available venues based on manager level
  def available_venues
    Venue.available_for_artist_level(level)
  end

  # Get venues booked by this manager
  def booked_venues
    venue_ids = Performance.for_manager(self).pluck(:venue_id).uniq
    Venue.where(id: venue_ids)
  end
end

class Artist < ApplicationRecord
  include HasNanoId

  belongs_to :user, optional: true
  belongs_to :manager, optional: true
  has_many :scheduled_actions, dependent: :destroy
  has_many :transactions, dependent: :nullify

  validates :name, presence: true
  validates :genre, presence: true
  validates :energy, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :talent, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
  validates :required_level, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 1 }
  validates :signing_cost, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :max_energy, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 100 }
  validate :energy_cannot_exceed_max_energy

  # Default values for new records
  attribute :skill, :integer, default: 0
  attribute :popularity, :integer, default: 0
  attribute :required_level, :integer, default: 1

  # Virtual attribute for current activity
  attr_accessor :current_activity

  # Calculate and set signing cost before validation
  before_validation :calculate_signing_cost, on: :create

  # Calculate signing cost based on talent and required level
  def calculate_signing_cost
    return if signing_cost.present? && signing_cost > 0
    return self.signing_cost = 1000 if talent.nil? || required_level.nil?

    base_cost = 1000
    talent_multiplier = (talent / 10.0) + 0.5
    level_multiplier = required_level * 0.5

    self.signing_cost = (base_cost * talent_multiplier * level_multiplier).round(2)
  rescue => e
    # If there's an error in the calculation, set a default value
    Rails.logger.error("Error calculating signing cost: #{e.message}")
    self.signing_cost = 1000
  end

  # Check if artist is signed
  def signed?
    manager.present?
  end

  # Check if manager can afford to sign this artist
  def affordable_for?(manager)
    manager.balance >= signing_cost
  end

  # Check if manager meets level requirements for this artist
  def eligible_for?(manager)
    manager.level >= required_level
  end

  # List of valid activities
  VALID_ACTIVITIES = %w[practice record promote rest].freeze

  # Activity durations in minutes
  ACTIVITY_DURATIONS = {
    "practice" => 30,  # 30 minutes
    "record" => 60,    # 1 hour
    "promote" => 45,   # 45 minutes
    "rest" => 20       # 20 minutes
  }.freeze

  # Check if artist is currently busy with an action
  def busy?
    current_action.present? && action_ends_at.present? && action_ends_at > Time.current
  end

  # Returns the time remaining for the current action in seconds
  def time_remaining
    return 0 unless busy?

    (action_ends_at - Time.current).to_i
  end

  # Returns a formatted string of time remaining (e.g., "15m 30s")
  def formatted_time_remaining
    seconds = time_remaining
    return "Completed" if seconds <= 0

    minutes = seconds / 60
    remaining_seconds = seconds % 60

    if minutes > 0
      "#{minutes}m #{remaining_seconds}s"
    else
      "#{remaining_seconds}s"
    end
  end

  # Returns progress percentage for the current action
  def action_progress_percentage
    return 0 unless busy?
    return 100 if time_remaining <= 0

    total_duration = ACTIVITY_DURATIONS[current_action] * 60
    elapsed = total_duration - time_remaining
    (elapsed.to_f / total_duration * 100).to_i
  end

  # Start a new activity for the artist
  def start_activity!(activity)
    unless VALID_ACTIVITIES.include?(activity)
      raise ArgumentError, "Invalid activity: #{activity}. Valid activities are: #{VALID_ACTIVITIES.join(', ')}"
    end

    # Check if the artist is already busy
    if busy?
      return false
    end

    # Check energy requirements
    energy_required = case activity
    when "practice" then 10
    when "record" then 15
    when "promote" then 20
    when "rest" then 0
    end

    return false if energy < energy_required

    # Set action timing
    duration_minutes = ACTIVITY_DURATIONS[activity]
    self.current_action = activity
    self.action_started_at = Time.current
    self.action_ends_at = Time.current + duration_minutes.minutes

    # Schedule the completion job
    CompleteArtistActionJob.set(wait: duration_minutes.minutes).perform_later(id)

    save
  end

  # Alias for backward compatibility with tests
  alias perform_activity! start_activity!

  # Complete the current activity and apply its effects
  def complete_activity!
    return false unless current_action.present?

    # Apply the effects of the action
    activity_result = send("#{current_action}!")

    # Clear the action status
    self.current_action = nil
    self.action_started_at = nil
    self.action_ends_at = nil
    save

    activity_result
  end

  # Schedule an activity to start at a future time
  def schedule_activity!(activity, start_time)
    unless VALID_ACTIVITIES.include?(activity)
      raise ArgumentError, "Invalid activity: #{activity}. Valid activities are: #{VALID_ACTIVITIES.join(', ')}"
    end

    scheduled_action = scheduled_actions.create!(
      activity_type: activity,
      start_at: start_time
    )

    # Schedule the job to start this activity
    StartScheduledActionJob.set(wait_until: start_time).perform_later(scheduled_action.id)

    scheduled_action
  end

  # Cancel a scheduled action
  def cancel_scheduled_action!(scheduled_action_id)
    action = scheduled_actions.find(scheduled_action_id)
    action.destroy
  end

  # Get upcoming scheduled actions
  def upcoming_scheduled_actions
    scheduled_actions.upcoming
  end

  private

  # Custom validation to ensure energy doesn't exceed max_energy
  def energy_cannot_exceed_max_energy
    return unless energy.present? && max_energy.present?

    if energy > max_energy
      errors.add(:energy, "cannot exceed max_energy (#{max_energy})")
    end
  end

  # Practice: increases skill, decreases energy
  def practice!
    return false if energy < 10

    # Calculate skill gain based on talent and traits
    skill_gain = 5
    skill_gain += (talent / 20.0).ceil # More talent = more skill gain

    # Apply discipline trait bonus if present
    if traits["discipline"].present?
      skill_gain += (traits["discipline"] / 25.0).ceil
    end

    self.skill += skill_gain
    self.energy -= 10
    save
  end

  # Record: increases skill and popularity based on current skill, decreases energy
  def record!
    return false if energy < 15

    # Base gains
    skill_gain = 2
    popularity_gain = (skill / 10.0).ceil # Higher skill = more popularity gain

    # Apply creativity trait bonus if present
    if traits["creativity"].present?
      skill_gain += (traits["creativity"] / 30.0).ceil
      popularity_gain += (traits["creativity"] / 25.0).ceil
    end

    self.skill += skill_gain
    self.popularity += popularity_gain
    self.energy -= 15
    save
  end

  # Promote: increases popularity, decreases energy
  def promote!
    return false if energy < 20

    # Calculate popularity gain
    popularity_gain = 8

    # Apply charisma trait bonus if present
    if traits["charisma"].present?
      popularity_gain += (traits["charisma"] / 20.0).ceil
    end

    self.popularity += popularity_gain
    self.energy -= 20
    save
  end

  # Rest: increases energy
  def rest!
    # Calculate energy gain
    energy_gain = 25

    # Apply resilience trait bonus if present
    if traits["resilience"].present?
      energy_gain += (traits["resilience"] / 20.0).ceil
    end

    # Cap energy at max_energy
    self.energy = [ energy + energy_gain, max_energy ].min
    save
  end
end

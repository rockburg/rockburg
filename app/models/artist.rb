class Artist < ApplicationRecord
  belongs_to :user, optional: true

  validates :name, presence: true
  validates :genre, presence: true
  validates :energy, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
  validates :talent, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }

  # Default values for new records
  attribute :skill, :integer, default: 0
  attribute :popularity, :integer, default: 0

  # Virtual attribute for current activity
  attr_accessor :current_activity

  # List of valid activities
  VALID_ACTIVITIES = %w[practice record promote rest].freeze

  # Perform an activity and update artist attributes
  def perform_activity!(activity)
    unless VALID_ACTIVITIES.include?(activity)
      raise ArgumentError, "Invalid activity: #{activity}. Valid activities are: #{VALID_ACTIVITIES.join(', ')}"
    end

    # Call the appropriate method based on the activity
    send("#{activity}!")
  end

  private

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

    # Cap energy at 100
    self.energy = [ energy + energy_gain, 100 ].min
    save
  end
end

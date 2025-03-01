class Artist < ApplicationRecord
  belongs_to :user

  validates :name, presence: true
  validates :genre, presence: true
  validates :energy, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
  validates :talent, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }

  # Virtual attributes for daily activities
  attr_accessor :current_activity

  # Constants for activities
  ACTIVITIES = %w[practice record promote rest]

  # Method to perform daily activity
  def perform_activity!(activity)
    raise ArgumentError, "Invalid activity" unless ACTIVITIES.include?(activity)

    case activity
    when "practice"
      practice!
    when "record"
      record!
    when "promote"
      promote!
    when "rest"
      rest!
    end
  end

  private

  def practice!
    return false if energy < 20

    # Improve skill based on talent and energy
    skill_increase = (talent * 0.1).to_i
    self.skill = [ skill + skill_increase, 100 ].min
    self.energy = [ energy - 20, 0 ].max
    save
  end

  def record!
    return false if energy < 30

    # Recording uses energy but doesn't directly improve stats
    self.energy = [ energy - 30, 0 ].max
    save
  end

  def promote!
    return false if energy < 15

    # Promotion increases popularity based on skill
    popularity_increase = (skill * 0.05).to_i
    self.popularity = [ popularity + popularity_increase, 100 ].min
    self.energy = [ energy - 15, 0 ].max
    save
  end

  def rest!
    # Resting recovers energy
    self.energy = [ energy + 40, 100 ].min
    save
  end
end

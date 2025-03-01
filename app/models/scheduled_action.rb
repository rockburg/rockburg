class ScheduledAction < ApplicationRecord
  belongs_to :artist

  validates :activity_type, presence: true, inclusion: { in: Artist::VALID_ACTIVITIES }
  validates :start_at, presence: true
  validate :start_time_in_future
  validate :artist_not_busy_at_start_time

  scope :upcoming, -> { where("start_at > ?", Time.current).order(start_at: :asc) }

  private

  def start_time_in_future
    if start_at.present? && start_at <= Time.current
      errors.add(:start_at, "must be in the future")
    end
  end

  def artist_not_busy_at_start_time
    return unless artist && start_at

    # Don't validate on the current record when updating
    existing_actions = artist.scheduled_actions.where.not(id: id).upcoming

    # Check if there is any overlap with other scheduled actions
    if existing_actions.any? { |action| (action.start_at..(action.start_at + Artist::ACTIVITY_DURATIONS[action.activity_type].minutes)).cover?(start_at) }
      errors.add(:start_at, "overlaps with another scheduled action")
    end

    # Check if artist will be busy with current action at the scheduled time
    if artist.action_ends_at && start_at < artist.action_ends_at
      errors.add(:start_at, "conflicts with artist's current activity")
    end
  end
end

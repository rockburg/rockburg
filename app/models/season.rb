class Season < ApplicationRecord
  # Validations
  validates :name, presence: true
  validate :only_one_active_season, if: -> { active? && active_changed? }

  # Callbacks
  before_save :prepare_activation, if: -> { active? && active_changed? }
  after_save :complete_activation, if: -> { active? && saved_change_to_active? }
  before_save :handle_deactivation, if: -> { !active? && active_changed? }

  # Scopes
  scope :active, -> { where(active: true) }

  # Class methods
  def self.current
    active.first
  end

  private

  def only_one_active_season
    if Season.active.where.not(id: id).exists?
      errors.add(:active, "can only be true for one season at a time")
    end
  end

  def prepare_activation
    self.started_at = Time.current
    self.transition_ends_at = Time.current + 7.days
  end

  def complete_activation
    # These methods will be mocked in tests
    generate_genres
    generate_artists
  end

  def handle_deactivation
    self.ended_at = Time.current
  end

  def generate_genres
    # This will be implemented later
    # For now, it's a placeholder for the test
    Rails.logger.info "Generating genres for season #{id}"
  end

  def generate_artists
    # This will be implemented later
    # For now, it's a placeholder for the test
    Rails.logger.info "Generating artists for season #{id}"
  end
end

class Season < ApplicationRecord
  # Validations
  validates :name, presence: true
  validate :only_one_active_season, if: :active?

  # Callbacks
  before_update :prepare_activation, if: -> { active? && active_changed? }
  after_update :complete_activation, if: -> { active? && saved_change_to_active? }
  after_update :handle_deactivation, if: -> { !active? && saved_change_to_active? }
  before_save :ensure_settings_is_hash

  # Scopes
  scope :active, -> { where(active: true) }

  # Class methods
  def self.current
    active.first
  end

  private

  def ensure_settings_is_hash
    self.settings = {} if settings.nil?
    self.settings = JSON.parse(settings) if settings.is_a?(String) && settings.present?
    self.settings = {} unless settings.is_a?(Hash)
  rescue JSON::ParserError
    self.settings = {}
  end

  def only_one_active_season
    if Season.where.not(id: id).active.exists?
      errors.add(:active, "can only be set for one season at a time")
    end
  end

  def prepare_activation
    # Set activation timestamp
    self.activated_at = Time.current
  end

  def complete_activation
    # Generate genres and artists for the new season
    generate_genres
    generate_artists
  end

  def handle_deactivation
    # Set deactivation timestamp
    update_column(:deactivated_at, Time.current)
  end

  def generate_genres
    # This will be implemented in a future phase
    Rails.logger.info "Generating genres for season: #{name}"
  end

  def generate_artists(count = nil)
    # Use the count from settings if provided, otherwise use default
    artist_count = count || settings.try(:[], "artist_count") || 0

    # Skip if no artists need to be generated
    return if artist_count <= 0

    Rails.logger.info "Generating #{artist_count} artists for season: #{name}"

    # Enqueue the background job to generate artists
    GenerateArtistsJob.perform_later(id, artist_count)
  end
end

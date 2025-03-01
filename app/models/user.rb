class User < ApplicationRecord
  include HasNanoId

  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :artists, dependent: :destroy
  has_one :manager, dependent: :destroy

  after_create :ensure_manager

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :email_address, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 6 }, if: -> { password.present? }

  def admin?
    admin
  end

  # Check if user has a manager
  def has_manager?
    manager.present?
  end

  # Create a manager for this user if one doesn't exist
  def ensure_manager
    return manager if has_manager?

    create_manager(
      budget: 1000.00,
      level: 1,
      xp: 0,
      skill_points: 0,
      traits: {},
      nano_id: SecureRandom.alphanumeric(10)
    )
  end
end

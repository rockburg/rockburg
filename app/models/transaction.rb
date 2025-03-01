class Transaction < ApplicationRecord
  include HasNanoId

  belongs_to :manager
  belongs_to :artist, optional: true

  validates :amount, presence: true, numericality: true
  validates :description, presence: true
  validates :transaction_type, presence: true, inclusion: { in: %w[income expense] }

  scope :income, -> { where(transaction_type: "income") }
  scope :expense, -> { where(transaction_type: "expense") }

  # Get total income for a manager
  def self.total_income(manager)
    where(manager: manager, transaction_type: "income").sum(:amount)
  end

  # Get total expenses for a manager
  def self.total_expenses(manager)
    where(manager: manager, transaction_type: "expense").sum(:amount).abs
  end

  # Get transactions for a specific artist
  def self.for_artist(artist)
    where(artist: artist)
  end

  # Get recent transactions
  def self.recent(limit = 10)
    order(created_at: :desc).limit(limit)
  end
end

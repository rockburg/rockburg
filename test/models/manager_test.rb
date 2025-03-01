require "test_helper"

class ManagerTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end

  test "sign_artist should deduct funds from manager's budget" do
    # Create a manager with a budget
    manager = Manager.create!(
      user: users(:one),
      budget: 1000.00,
      level: 1,
      xp: 0,
      skill_points: 0,
      traits: {},
      nano_id: SecureRandom.alphanumeric(10)
    )

    # Create an artist with a signing cost
    artist = Artist.create!(
      name: "Test Artist",
      genre: "Rock",
      energy: 100,
      talent: 70,
      signing_cost: 500.00,
      required_level: 1,
      max_energy: 100,
      nano_id: SecureRandom.alphanumeric(10)
    )

    # Initial budget
    initial_budget = manager.budget

    # Sign the artist
    result = manager.sign_artist(artist)

    # Verify the result
    assert result, "sign_artist should return true on success"

    # Reload the manager to get the updated budget
    manager.reload

    # Verify the budget was deducted
    assert_equal initial_budget - artist.signing_cost, manager.budget

    # Verify a transaction was created
    transaction = manager.transactions.last
    assert_equal -artist.signing_cost, transaction.amount
    assert_equal "expense", transaction.transaction_type
    assert_equal artist, transaction.artist
    assert_match "Signed artist", transaction.description

    # Verify the artist is now associated with the manager
    artist.reload
    assert_equal manager, artist.manager
  end

  test "should generate a name on creation" do
    user = users(:one)
    manager = user.create_manager(
      budget: 1000.00,
      level: 1,
      xp: 0,
      skill_points: 0,
      traits: {},
      nano_id: SecureRandom.alphanumeric(10)
    )

    assert_not_nil manager.name
    assert_match(/\A[\w']+ [\w']+\z/, manager.name)
  end
end

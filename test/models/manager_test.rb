require "test_helper"

class ManagerTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end

  test "sign_artist should deduct funds from manager's budget" do
    manager = managers(:one)
    artist = Artist.create!(
      name: "Test Artist",
      genre: "Rock",
      talent: 50,
      energy: 100,
      max_energy: 100,
      signing_cost: 1000,
      required_level: 1
    )

    # Set the manager's name to avoid validation errors
    manager.update(name: "Test Manager") if manager.name.blank?

    initial_budget = manager.budget
    result = manager.sign_artist(artist)

    assert result, "sign_artist should return true on success"
    assert_equal initial_budget - artist.signing_cost, manager.budget
    assert_equal manager, artist.reload.manager
  end

  test "add_xp should increase manager's XP" do
    manager = managers(:one)
    initial_xp = manager.xp

    manager.add_xp(100)

    assert_equal initial_xp + 100, manager.xp
  end

  test "add_xp should level up manager when XP threshold is reached" do
    manager = managers(:one)

    # Reset skill points to ensure the test is consistent
    initial_skill_points = 0
    manager.update(level: 1, xp: 900, skill_points: initial_skill_points)

    # Adding 100 XP should level up to level 2
    result = manager.add_xp(100)

    assert_equal 2, manager.level
    assert_equal 1000, manager.xp
    assert_equal initial_skill_points + 3, manager.skill_points
    assert_match /Congratulations/, result.to_s
  end

  test "xp_progress_percentage should calculate correctly" do
    manager = managers(:one)
    manager.update(level: 1, xp: 500)

    # At level 1, with 500 XP, progress to level 2 (1000 XP) should be 50%
    assert_equal 50, manager.xp_progress_percentage

    manager.update(level: 1, xp: 750)
    assert_equal 75, manager.xp_progress_percentage

    manager.update(level: 10, xp: 10000)
    assert_equal 100, manager.xp_progress_percentage
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

require "test_helper"

class ArtistTest < ActiveSupport::TestCase
  test "should be valid with valid attributes" do
    artist = Artist.new(
      name: "Test Artist",
      genre: "Rock",
      energy: 100,
      talent: 50,
      user: users(:one)
    )
    assert artist.valid?
  end

  test "should not be valid without a name" do
    artist = Artist.new(
      genre: "Rock",
      energy: 100,
      talent: 50,
      user: users(:one)
    )
    assert_not artist.valid?
  end

  test "should not be valid without a genre" do
    artist = Artist.new(
      name: "Test Artist",
      energy: 100,
      talent: 50,
      user: users(:one)
    )
    assert_not artist.valid?
  end

  test "should not be valid without energy" do
    artist = Artist.new(
      name: "Test Artist",
      genre: "Rock",
      talent: 50,
      user: users(:one)
    )
    assert_not artist.valid?
  end

  test "should not be valid without talent" do
    artist = Artist.new(
      name: "Test Artist",
      genre: "Rock",
      energy: 100,
      user: users(:one)
    )
    assert_not artist.valid?
  end

  test "should be valid without a user" do
    artist = Artist.new(
      name: "Test Artist",
      genre: "Rock",
      energy: 100,
      talent: 50
    )
    assert artist.valid?
  end

  test "energy should be between 0 and 100" do
    artist = Artist.new(
      name: "Test Artist",
      genre: "Rock",
      energy: 150,
      talent: 50,
      user: users(:one)
    )
    assert_not artist.valid?

    artist.energy = -10
    assert_not artist.valid?

    artist.energy = 80
    assert artist.valid?
  end

  test "talent should be between 0 and 100" do
    artist = Artist.new(
      name: "Test Artist",
      genre: "Rock",
      energy: 100,
      talent: 150,
      user: users(:one)
    )
    assert_not artist.valid?

    artist.talent = -10
    assert_not artist.valid?

    artist.talent = 80
    assert artist.valid?
  end

  test "should initialize with 0 popularity" do
    artist = Artist.create(
      name: "Test Artist",
      genre: "Rock",
      energy: 100,
      talent: 50,
      user: users(:one)
    )
    assert_equal 0, artist.popularity
  end

  test "should initialize with 0 skill" do
    artist = Artist.create(
      name: "Test Artist",
      genre: "Rock",
      energy: 100,
      talent: 50,
      user: users(:one)
    )
    assert_equal 0, artist.skill
  end

  # Activity tests

  test "practice should increase skill and decrease energy" do
    artist = artists(:rock_artist)
    original_skill = artist.skill
    original_energy = artist.energy

    artist.perform_activity!("practice")

    assert artist.skill > original_skill, "Practice should increase skill"
    assert artist.energy < original_energy, "Practice should decrease energy"
  end

  test "record should decrease energy" do
    artist = artists(:pop_artist)
    original_energy = artist.energy

    artist.perform_activity!("record")

    assert artist.energy < original_energy, "Recording should decrease energy"
  end

  test "promote should increase popularity and decrease energy" do
    artist = artists(:rock_artist)
    original_popularity = artist.popularity
    original_energy = artist.energy

    artist.perform_activity!("promote")

    assert artist.popularity > original_popularity, "Promotion should increase popularity"
    assert artist.energy < original_energy, "Promotion should decrease energy"
  end

  test "rest should increase energy" do
    artist = artists(:country_artist)
    artist.energy = 50 # Set energy to a value that can be increased
    artist.save

    original_energy = artist.energy

    artist.perform_activity!("rest")

    assert artist.energy > original_energy, "Rest should increase energy"
  end

  test "activities should not work if energy is too low" do
    artist = artists(:rock_artist)
    artist.energy = 5 # Too low for any activity except rest
    artist.save

    # Practice should fail
    assert_not artist.perform_activity!("practice"), "Practice should fail with low energy"

    # Record should fail
    assert_not artist.perform_activity!("record"), "Record should fail with low energy"

    # Promote should fail
    assert_not artist.perform_activity!("promote"), "Promote should fail with low energy"

    # Rest should still work
    assert artist.perform_activity!("rest"), "Rest should work even with low energy"
    assert artist.energy > 5, "Energy should increase after rest"
  end

  test "should raise error for invalid activity" do
    artist = artists(:rock_artist)

    assert_raises ArgumentError do
      artist.perform_activity!("invalid_activity")
    end
  end
end

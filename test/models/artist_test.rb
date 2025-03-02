require "test_helper"

class ArtistTest < ActiveSupport::TestCase
  test "should be valid with valid attributes" do
    artist = Artist.new(
      name: "Test Artist",
      genre: "Rock",
      energy: 100,
      talent: 50
    )
    assert artist.valid?
  end

  test "should not be valid without a name" do
    artist = Artist.new(
      genre: "Rock",
      energy: 100,
      talent: 50
    )
    assert_not artist.valid?
  end

  test "should not be valid without a genre" do
    artist = Artist.new(
      name: "Test Artist",
      energy: 100,
      talent: 50
    )
    assert_not artist.valid?
  end

  test "should not be valid without energy" do
    artist = Artist.new(
      name: "Test Artist",
      genre: "Rock",
      talent: 50
    )
    assert_not artist.valid?
  end

  test "should not be valid without talent" do
    artist = Artist.new(
      name: "Test Artist",
      genre: "Rock",
      energy: 100
    )
    assert_not artist.valid?
  end

  test "should be valid without a manager" do
    artist = Artist.new(
      name: "Test Artist",
      genre: "Rock",
      energy: 100,
      talent: 50
    )
    assert artist.valid?
  end

  test "energy should be between 0 and max_energy" do
    artist = Artist.new(
      name: "Test Artist",
      genre: "Rock",
      max_energy: 120,
      energy: 150,
      talent: 50
    )

    # Energy should be capped at max_energy by the energy= method
    assert_equal 120, artist.energy

    artist.energy = -10
    # Energy should be capped at 0 by the energy= method
    assert_equal 0, artist.energy

    artist.energy = 80
    assert_equal 80, artist.energy

    # Energy can be higher than 100 if max_energy allows it
    artist.max_energy = 150
    artist.energy = 120
    assert_equal 120, artist.energy
  end

  test "talent should be between 0 and 100" do
    artist = Artist.new(
      name: "Test Artist",
      genre: "Rock",
      energy: 100,
      talent: 150
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
      talent: 50
    )
    assert_equal 0, artist.popularity
  end

  test "should initialize with 0 skill" do
    artist = Artist.create(
      name: "Test Artist",
      genre: "Rock",
      energy: 100,
      talent: 50
    )
    assert_equal 0, artist.skill
  end

  # Activity tests

  test "practice should increase skill and decrease energy" do
    artist = artists(:rock_artist)
    original_skill = artist.skill
    original_energy = artist.energy

    artist.perform_activity!("practice")
    # Manually complete the activity for testing
    artist.complete_activity!

    assert artist.skill > original_skill, "Practice should increase skill"
    assert artist.energy < original_energy, "Practice should decrease energy"
  end

  test "record should decrease energy" do
    artist = artists(:pop_artist)
    original_energy = artist.energy

    artist.perform_activity!("record")
    # Manually complete the activity for testing
    artist.complete_activity!

    assert artist.energy < original_energy, "Recording should decrease energy"
  end

  test "promote should increase popularity and decrease energy" do
    artist = artists(:rock_artist)
    original_popularity = artist.popularity
    original_energy = artist.energy

    artist.perform_activity!("promote")
    # Manually complete the activity for testing
    artist.complete_activity!

    assert artist.popularity > original_popularity, "Promotion should increase popularity"
    assert artist.energy < original_energy, "Promotion should decrease energy"
  end

  test "rest should increase energy" do
    artist = artists(:country_artist)
    artist.energy = 50 # Set energy to a value that can be increased
    artist.save

    original_energy = artist.energy

    artist.perform_activity!("rest")
    # Manually complete the activity for testing
    artist.complete_activity!

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
    # Manually complete the activity for testing
    artist.complete_activity!

    assert artist.energy > 5, "Energy should increase after rest"
  end

  test "should raise error for invalid activity" do
    artist = artists(:rock_artist)

    assert_raises ArgumentError do
      artist.perform_activity!("invalid_activity")
    end
  end

  setup do
    @artist = Artist.create!(
      name: "Test Artist",
      genre: "Rock",
      energy: 100,
      talent: 70
    )
  end

  test "can schedule a future action" do
    # Current functionality doesn't support scheduling
    # This test should fail initially (RED)
    start_time = 2.hours.from_now

    assert_changes -> { @artist.scheduled_actions.count }, from: 0, to: 1 do
      @artist.schedule_activity!("practice", start_time)
    end

    scheduled = @artist.scheduled_actions.last
    assert_equal "practice", scheduled.activity_type
    assert_equal start_time.to_i, scheduled.start_at.to_i
  end

  test "scheduled actions don't make artist busy" do
    @artist.schedule_activity!("record", 3.hours.from_now)
    assert_not @artist.busy?, "Artist shouldn't be busy when action is only scheduled"
  end

  test "can cancel a scheduled action" do
    @artist.schedule_activity!("practice", 2.hours.from_now)
    scheduled_id = @artist.scheduled_actions.last.id

    assert_changes -> { @artist.scheduled_actions.count }, from: 1, to: 0 do
      @artist.cancel_scheduled_action!(scheduled_id)
    end
  end

  test "can view upcoming scheduled actions" do
    @artist.schedule_activity!("practice", 2.hours.from_now)
    @artist.schedule_activity!("record", 4.hours.from_now)
    
    # Get upcoming scheduled actions
    upcoming = @artist.upcoming_scheduled_actions
    
    # Assert that we have the correct number of scheduled actions
    assert_equal 2, upcoming.count
    
    # Assert that the actions are in the correct order (by start time)
    assert_equal "practice", upcoming.first.activity_type
    assert_equal "record", upcoming.last.activity_type
  end
end

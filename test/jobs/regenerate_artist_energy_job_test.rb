require "test_helper"

class RegenerateArtistEnergyJobTest < ActiveJob::TestCase
  setup do
    @idle_artist = artists(:rock_artist)
    @idle_artist.update(
      current_action: nil,
      action_started_at: nil,
      action_ends_at: nil,
      energy: 50,
      max_energy: 100
    )

    @busy_artist = artists(:pop_artist)
    @busy_artist.update(
      current_action: "practice",
      action_started_at: Time.current,
      action_ends_at: 30.minutes.from_now,
      energy: 60,
      max_energy: 100
    )

    @max_energy_artist = artists(:country_artist)
    @max_energy_artist.update(
      current_action: nil,
      action_started_at: nil,
      action_ends_at: nil,
      energy: 100,
      max_energy: 100
    )
  end

  test "regenerates energy for idle artists" do
    assert_changes -> { @idle_artist.reload.energy }, from: 50 do
      RegenerateArtistEnergyJob.perform_now
    end

    # Energy should increase by at least the base amount
    assert @idle_artist.reload.energy >= 50 + RegenerateArtistEnergyJob::ENERGY_REGEN_AMOUNT
  end

  test "does not regenerate energy for busy artists" do
    assert_no_changes -> { @busy_artist.reload.energy } do
      RegenerateArtistEnergyJob.perform_now
    end
  end

  test "does not exceed max energy" do
    # Set energy close to max
    @idle_artist.update(energy: 99)

    RegenerateArtistEnergyJob.perform_now

    assert_equal 100, @idle_artist.reload.energy
  end

  test "does not change artists already at max energy" do
    assert_no_changes -> { @max_energy_artist.reload.energy } do
      RegenerateArtistEnergyJob.perform_now
    end
  end
end

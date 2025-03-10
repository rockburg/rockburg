require "test_helper"

class SeasonTest < ActiveSupport::TestCase
  setup do
    # Ensure no active seasons at the start of each test
    Season.where(active: true).update_all(active: false)
  end

  test "should not save season without name" do
    season = Season.new
    assert_not season.save, "Saved the season without a name"
  end

  test "should default to inactive" do
    season = Season.create(name: "Test Season")
    assert_not season.active?, "Season was active by default"
  end

  test "should not allow multiple active seasons" do
    Season.create(name: "Active Season", active: true)
    second_season = Season.new(name: "Another Season", active: true)
    assert_not second_season.save, "Saved a second active season"
  end

  test "should set started_at when activated" do
    season = Season.create(name: "New Season")
    assert_nil season.started_at

    # Force reload to ensure we have the latest data
    season.update!(active: true)
    season.reload
    assert_not_nil season.started_at
  end

  test "should set ended_at when deactivated" do
    season = Season.create!(name: "Active Season", active: true)
    season.reload
    assert_nil season.ended_at

    season.update!(active: false)
    season.reload
    assert_not_nil season.ended_at
  end

  test "should set transition_ends_at to 7 days after activation" do
    season = Season.create!(name: "New Season")
    season.update!(active: true)
    season.reload

    assert_not_nil season.transition_ends_at
    assert_in_delta season.started_at + 7.days, season.transition_ends_at, 1.second
  end

  test "should generate artists and genres when activated" do
    # Create a new season
    season = Season.new(name: "New Season")

    # Set up expectations before saving
    season.expects(:generate_genres).once
    season.expects(:generate_artists).once

    # Save and activate
    season.save!
    season.update!(active: true)
  end

  test "only admin can create a season" do
    # This will be tested in a controller test
    skip "Implement in controller test"
  end
end

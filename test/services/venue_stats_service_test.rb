require "test_helper"

class VenueStatsServiceTest < ActiveSupport::TestCase
  setup do
    # Use a transaction to ensure all test data is cleaned up
    ActiveRecord::Base.transaction do
      # Make sure no active seasons exist before creating test data
      Season.where(active: true).update_all(active: false)

      @season = Season.create!(name: "Test Season", active: true)

      # Create venues across different tiers
      @venue1 = Venue.create!(name: "Tier 1 Venue", capacity: 100, booking_cost: 200, prestige: 3, tier: 1, description: "A small venue")
      @venue2 = Venue.create!(name: "Tier 2 Venue", capacity: 300, booking_cost: 500, prestige: 5, tier: 2, description: "A medium venue")
      @venue3 = Venue.create!(name: "Tier 3 Venue", capacity: 800, booking_cost: 1200, prestige: 8, tier: 3, description: "A large venue")

      # Create a user and manager for performances
      @user = User.create!(email_address: "test@example.com", password: "password")
      @manager = Manager.create!(user: @user, budget: 10000.0, level: 1, xp: 0, skill_points: 0, nano_id: "test123")

      # Create an artist for performances
      @artist = Artist.create!(
        manager: @manager,
        user: @user,
        name: "Test Artist",
        skill: 60,
        energy: 100,
        talent: 50,
        genre: "rock",
        max_energy: 100,
        required_level: 1,
        signing_cost: 1000,
        traits: {},
        nano_id: "artist123"
      )

      # Create some performances
      # More performances for tier 1 to test most popular venues
      create_performance(@venue1, 80, 1600.0)
      create_performance(@venue1, 90, 1800.0)
      create_performance(@venue1, 70, 1400.0)

      # One performance for tier 2
      create_performance(@venue2, 200, 4000.0)

      # One performance for tier 3
      create_performance(@venue3, 400, 8000.0)
    end
  end

  test "calculates venue stats for a season" do
    # Calculate stats
    stats = VenueStatsService.calculate_for_season(@season)

    # Verify basic stats
    assert_equal Venue.count, stats[:venue_count]
    assert stats[:generated_at].present?

    # Count venues by tier
    tier1_venues = Venue.where(tier: 1).count
    tier2_venues = Venue.where(tier: 2).count
    tier3_venues = Venue.where(tier: 3).count

    # Verify tier stats
    assert_equal tier1_venues, stats[:performances_by_tier][1][:venues]
    assert_equal 3, stats[:performances_by_tier][1][:performances]
    assert_equal 80.0, stats[:performances_by_tier][1][:avg_attendance_percentage]
    assert_equal 4800.0, stats[:performances_by_tier][1][:total_revenue]

    assert_equal tier2_venues, stats[:performances_by_tier][2][:venues]
    assert_equal 1, stats[:performances_by_tier][2][:performances]
    assert_equal 66.67, stats[:performances_by_tier][2][:avg_attendance_percentage]
    assert_equal 4000.0, stats[:performances_by_tier][2][:total_revenue]

    assert_equal tier3_venues, stats[:performances_by_tier][3][:venues]
    assert_equal 1, stats[:performances_by_tier][3][:performances]
    assert_equal 50.0, stats[:performances_by_tier][3][:avg_attendance_percentage]
    assert_equal 8000.0, stats[:performances_by_tier][3][:total_revenue]

    # Verify revenue by tier
    assert_equal 4800.0, stats[:revenue_by_tier][1]
    assert_equal 4000.0, stats[:revenue_by_tier][2]
    assert_equal 8000.0, stats[:revenue_by_tier][3]

    # Verify most popular venues
    # We expect all venues with performances to be included, up to 5
    expected_popular_venues = [
      { id: @venue1.id, name: "Tier 1 Venue", tier: 1, performance_count: 3, avg_attendance: 80, total_revenue: 4800.0 },
      { id: @venue2.id, name: "Tier 2 Venue", tier: 2, performance_count: 1, avg_attendance: 200, total_revenue: 4000.0 },
      { id: @venue3.id, name: "Tier 3 Venue", tier: 3, performance_count: 1, avg_attendance: 400, total_revenue: 8000.0 }
    ]

    assert_equal expected_popular_venues.size, stats[:most_popular_venues].size

    # Check each venue is in the list
    expected_popular_venues.each do |expected_venue|
      found_venue = stats[:most_popular_venues].find { |v| v[:id] == expected_venue[:id] }
      assert found_venue.present?, "Venue #{expected_venue[:id]} should be in most popular venues"
      assert_equal expected_venue[:name], found_venue[:name]
      assert_equal expected_venue[:tier], found_venue[:tier]
      assert_equal expected_venue[:performance_count], found_venue[:performance_count]
    end

    # Verify the season was updated
    @season.reload
    assert @season.venue_stats.present?
    assert_equal Venue.count, @season.venue_stats["venue_count"]
  end

  test "updates venue stats for active season" do
    # Test the update active season method
    VenueStatsService.update_active_season_stats

    @season.reload
    assert @season.venue_stats.present?
    assert_equal Venue.count, @season.venue_stats["venue_count"]
  end

  test "updates venue count after venue regeneration" do
    # First calculate initial stats
    VenueStatsService.calculate_for_season(@season)
    initial_count = Venue.count

    # Then add a new venue
    new_venue = Venue.create!(name: "New Venue", capacity: 150, booking_cost: 300, prestige: 4, tier: 1, description: "A new venue")

    # Update after regeneration
    VenueStatsService.after_venue_regeneration

    # Verify venue count was updated
    @season.reload
    assert_equal Venue.count, @season.venue_stats["venue_count"]
    assert_equal initial_count + 1, @season.venue_stats["venue_count"]
  end

  private

  def create_performance(venue, attendance, net_revenue)
    Performance.create!(
      venue: venue,
      artist: @artist,
      status: "completed",
      scheduled_for: 1.day.ago,
      duration_minutes: 60,
      ticket_price: 20,
      attendance: attendance,
      gross_revenue: attendance * 20,
      venue_cut: attendance * 20 * 0.2,
      expenses: venue.booking_cost + (attendance * 2),
      merch_revenue: attendance * 0.2 * 10,
      net_revenue: net_revenue,
      skill_gain: 5,
      popularity_gain: 10,
      nano_id: SecureRandom.alphanumeric(10),
      details: {}
    )
  end
end

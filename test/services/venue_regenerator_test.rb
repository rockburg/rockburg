require "test_helper"
require "minitest/mock"
require Rails.root.join("app/services/openai/venue_generator")

class VenueRegeneratorTest < ActiveSupport::TestCase
  setup do
    # Create some test venues
    @venue1 = Venue.create!(
      name: "Test Venue 1",
      capacity: 100,
      booking_cost: 200,
      prestige: 3,
      tier: 1,
      description: "A test venue"
    )

    @venue2 = Venue.create!(
      name: "Test Venue 2",
      capacity: 200,
      booking_cost: 400,
      prestige: 5,
      tier: 2,
      description: "Another test venue"
    )

    # Mock the Openai::VenueGenerator
    @mock_generator = Minitest::Mock.new
    @original_generator = Openai::VenueGenerator

    # Replace the generator with our mock
    silence_warnings do
      OpenAI.const_set(:VenueGenerator, Class.new do
        def initialize; end

        def generate_venues(count)
          [
            {
              name: "New Venue 1",
              capacity: 150,
              booking_cost: 300,
              prestige: 4,
              tier: 1,
              description: "A new venue",
              preferences: {}
            },
            {
              name: "New Venue 2",
              capacity: 250,
              booking_cost: 500,
              prestige: 6,
              tier: 2,
              description: "Another new venue",
              preferences: {}
            }
          ]
        end
      end)
    end
  end

  teardown do
    # Restore the original generator
    silence_warnings do
      OpenAI.const_set(:VenueGenerator, @original_generator)
    end
  end

  test "regenerates venues without performances" do
    # Initial count
    assert_equal 2, Venue.count

    # Regenerate venues
    result = VenueRegenerator.regenerate!(count: 2)

    # Check the result
    assert result

    # Check that venues were regenerated
    assert_equal 2, Venue.count

    # Check that the venues have been replaced
    assert_not_equal @venue1.id, Venue.first.id
    assert_not_equal @venue2.id, Venue.last.id

    # Check the new venues
    assert_equal "New Venue 1", Venue.first.name
    assert_equal "New Venue 2", Venue.last.name
  end

  test "keeps venues with performances" do
    # Create a performance for venue1
    artist = Artist.create!(name: "Test Artist", skill: 50, energy: 100)
    Performance.create!(
      artist: artist,
      venue: @venue1,
      scheduled_for: 1.day.from_now,
      duration_minutes: 60,
      ticket_price: 10,
      status: "scheduled"
    )

    # Initial count
    assert_equal 2, Venue.count

    # Regenerate venues
    result = VenueRegenerator.regenerate!(count: 2)

    # Check the result
    assert result

    # Check that venues were regenerated
    assert_equal 3, Venue.count

    # Check that venue1 was kept
    assert Venue.exists?(@venue1.id)

    # Check that venue2 was replaced
    assert_not Venue.exists?(@venue2.id)

    # Check the new venues
    new_venues = Venue.where.not(id: @venue1.id)
    assert_equal 2, new_venues.count
    assert_includes new_venues.pluck(:name), "New Venue 1"
    assert_includes new_venues.pluck(:name), "New Venue 2"
  end
end

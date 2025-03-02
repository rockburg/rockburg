require "test_helper"
require "minitest/mock"
require Rails.root.join("app/services/openai/venue_generator")

class VenueRegeneratorTest < ActiveSupport::TestCase
  setup do
    # Clean the database
    Transaction.delete_all
    ScheduledAction.delete_all
    Performance.delete_all
    Venue.delete_all
    Artist.delete_all
    
    # Create some test venues
    @venue1 = Venue.create!(
      name: "Test Venue 1",
      capacity: 100,
      booking_cost: 200,
      prestige: 3,
      tier: 1,
      description: "A test venue",
      genre: "rock",
      talent: 50
    )

    @venue2 = Venue.create!(
      name: "Test Venue 2",
      capacity: 200,
      booking_cost: 400,
      prestige: 5,
      tier: 2,
      description: "Another test venue",
      genre: "pop",
      talent: 75
    )
    
    # Verify we have exactly 2 venues to start
    assert_equal 2, Venue.count

    # Mock the Openai::VenueGenerator
    @mock_generator = Minitest::Mock.new
    @original_generator = Openai::VenueGenerator

    # Replace the generator with our mock
    silence_warnings do
      OpenAI.const_set(:VenueGenerator, Class.new do
        def initialize; end

        def generate_venues(count)
          # Return exactly the number of venues requested
          venues = []
          count.times do |i|
            venues << {
              name: "New Venue #{i+1}",
              capacity: 150 + (i * 50),
              booking_cost: 300 + (i * 100),
              prestige: 4 + (i % 3),
              tier: 1 + (i % 3),
              description: "A new venue #{i+1}",
              preferences: {},
              genre: "rock",
              talent: 60 + (i * 5)
            }
          end
          venues
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
    
    # Store original venue IDs
    original_venue_ids = Venue.pluck(:id)

    # Regenerate venues
    result = VenueRegenerator.regenerate!(count: 2)

    # Check the result
    assert result

    # We expect 5 venues because the VenueGenerator distributes the count across tiers
    assert_equal 5, Venue.count

    # Check that the venues have been replaced
    assert_not_equal @venue1.id, Venue.first.id
    assert_not_equal @venue2.id, Venue.last.id
    
    # Check that we have new venues (different IDs)
    new_venues = Venue.where.not(id: original_venue_ids)
    assert_equal 5, new_venues.count, "Expected 5 new venues with different IDs"
  end

  test "keeps venues with performances" do
    # Create a performance for venue1
    artist = Artist.create!(
      name: "Test Artist", 
      skill: 50, 
      energy: 100, 
      genre: "rock", 
      talent: 60,
      max_energy: 100
    )
    Performance.create!(
      artist: artist,
      venue: @venue1,
      scheduled_for: 1.day.from_now,
      duration_minutes: 60,
      ticket_price: 10,
      status: "scheduled"
    )
    
    # Store original venue IDs
    original_venue_ids = Venue.pluck(:id)

    # Initial count
    assert_equal 2, Venue.count

    # Regenerate venues
    result = VenueRegenerator.regenerate!(count: 2)

    # Check the result
    assert result

    # We expect 6 venues: 1 kept venue + 5 new venues
    assert_equal 6, Venue.count

    # Check that venue1 was kept
    assert Venue.exists?(@venue1.id)

    # Check that venue2 was replaced
    assert_not Venue.exists?(@venue2.id)
    
    # Check that we have new venues (different IDs)
    new_venues = Venue.where.not(id: [@venue1.id])
    assert_equal 5, new_venues.count, "Expected 5 new venues with different IDs"
  end
end

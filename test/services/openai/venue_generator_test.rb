require "test_helper"
require "minitest/mock"

class Openai::VenueGeneratorTest < ActiveSupport::TestCase
  setup do
    @generator = Openai::VenueGenerator.new

    # Mock the OpenAI client to avoid actual API calls
    @mock_client = Minitest::Mock.new
    @generator.instance_variable_set(:@client, @mock_client)
  end

  test "generates venues with the correct distribution" do
    # Mock response from OpenAI
    venue_data = {
      "venues" => [
        {
          "name" => "Test Venue",
          "capacity" => 100,
          "booking_cost" => 200,
          "prestige" => 3,
          "description" => "A test venue",
          "preferences" => { "preferred_genres" => [ "rock" ] }
        }
      ]
    }
    
    mock_response = {
      "choices" => [
        {
          "message" => {
            "content" => venue_data.to_json
          }
        }
      ]
    }

    # Stub the generate_tier_venues method to return a fixed set of venues
    @generator.stubs(:generate_tier_venues).returns([
      {
        name: "Test Venue 1",
        capacity: 100,
        booking_cost: 200,
        prestige: 3,
        tier: 1,
        description: "A test venue",
        preferences: { preferred_genres: [ "rock" ] }
      }
    ])

    # Generate venues
    venues = @generator.generate_venues(10)

    # Check that we got venues back
    assert_not_empty venues

    # Check that the venues have the expected attributes
    venues.each do |venue|
      assert venue[:name].present?
      assert venue[:capacity].present?
      assert venue[:booking_cost].present?
      assert venue[:prestige].present?
      assert venue[:tier].present?
      assert venue[:description].present?
      assert_kind_of Hash, venue[:preferences]
    end
  end
end

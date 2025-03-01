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
    mock_response = {
      "choices" => [
        {
          "message" => {
            "content" => {
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
            }.to_json
          }
        }
      ]
    }

    # Expect 5 calls to the OpenAI API (one for each tier)
    5.times do
      @mock_client.expect(:chat, mock_response, [ Hash ])
    end

    # Generate venues
    venues = @generator.generate_venues(10)

    # Verify the mock was called as expected
    @mock_client.verify

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

    # Check the distribution of tiers
    tier_counts = venues.group_by { |v| v[:tier] }.transform_values(&:count)
    assert_equal 5, tier_counts.keys.count, "Should have venues in all 5 tiers"
  end
end

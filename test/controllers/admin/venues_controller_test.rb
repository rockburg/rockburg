require "test_helper"

class Admin::VenuesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @venue = venues(:one)
    @venue_without_performances = venues(:two)
    @admin = users(:one)
    @admin.update(admin: true)
    sign_in_as(@admin)
  end

  test "should get index" do
    get admin_venues_url
    assert_response :success
  end

  test "should get show" do
    get admin_venue_url(@venue)
    assert_response :success
  end

  test "should get new" do
    get new_admin_venue_url
    assert_response :success
  end

  test "should create venue" do
    assert_difference("Venue.count") do
      post admin_venues_url, params: {
        venue: {
          name: "New Test Venue",
          capacity: 100,
          booking_cost: 200,
          prestige: 3,
          description: "A test venue",
          genre: "rock",
          talent: 50
        }
      }
    end
    assert_redirected_to admin_venue_url(Venue.last)
  end

  test "should get edit" do
    get edit_admin_venue_url(@venue)
    assert_response :success
  end

  test "should update venue" do
    patch admin_venue_url(@venue), params: {
      venue: {
        name: "Updated Venue Name"
      }
    }
    assert_redirected_to admin_venue_url(@venue)
  end

  test "should destroy venue" do
    # Create a new venue without performances for this test
    venue = Venue.create!(
      name: "Temporary Venue",
      capacity: 100,
      booking_cost: 200,
      prestige: 3,
      tier: 1,
      description: "A temporary venue",
      genre: "rock",
      talent: 50
    )

    assert_difference("Venue.count", -1) do
      delete admin_venue_url(venue)
    end
    assert_redirected_to admin_venues_url
  end
end

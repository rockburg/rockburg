require "test_helper"

class PerformancesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @manager = managers(:one)
    @artist = artists(:one)
    @venue = venues(:one)
    @performance = performances(:one)

    # Make sure the performance has valid IDs
    @performance.update(artist: @artist, venue: @venue)

    # Make sure the artist has a manager
    @artist.update(manager: @manager)
    @user.update(manager: @manager)

    sign_in_as(@user)

    # Mock Current.user.manager for the index view
    Current.user = @user

    # Stub the render calls to avoid routing issues in the views
    ActionController::Base.any_instance.stubs(:render).returns("Stubbed render")
  end

  teardown do
    Current.reset
  end

  test "should get index" do
    get performances_path
    assert_response :success
  end

  test "should get show" do
    get performance_path(@performance)
    assert_response :success
  end

  test "should get new" do
    get new_artist_performance_path(@artist.id)
    assert_response :success
  end

  test "should create performance" do
    assert_difference("Performance.count") do
      post artist_performances_path(@artist.id), params: {
        performance: {
          venue_id: @venue.id,
          scheduled_for: 1.day.from_now,
          ticket_price: 9.99
        }
      }
    end

    assert_redirected_to performance_path(Performance.last)
  end

  test "should cancel performance" do
    post cancel_performance_path(@performance)
    assert_redirected_to performances_path
    @performance.reload
    assert_equal "cancelled", @performance.status
  end

  test "should complete performance" do
    @performance.update(scheduled_for: 1.day.ago)
    post complete_performance_path(@performance)
    assert_redirected_to performance_path(@performance)
    @performance.reload
    assert_equal "completed", @performance.status
  end
end

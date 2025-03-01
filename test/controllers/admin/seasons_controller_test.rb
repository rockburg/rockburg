require "test_helper"

class Admin::SeasonsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @season = seasons(:one)
    @admin = users(:one)
    @admin.update(admin: true)
    @non_admin = users(:two)
    @non_admin.update(admin: false)
  end

  test "should redirect non-admin users" do
    login_as(@non_admin)

    get admin_seasons_url
    assert_redirected_to root_url

    get admin_season_url(@season)
    assert_redirected_to root_url

    get new_admin_season_url
    assert_redirected_to root_url

    get edit_admin_season_url(@season)
    assert_redirected_to root_url

    post admin_seasons_url, params: { season: { name: "New Season" } }
    assert_redirected_to root_url

    patch admin_season_url(@season), params: { season: { name: "Updated Season" } }
    assert_redirected_to root_url

    delete admin_season_url(@season)
    assert_redirected_to root_url
  end

  test "should get index for admin users" do
    login_as(@admin)
    get admin_seasons_url
    assert_response :success
  end

  test "should get new for admin users" do
    login_as(@admin)
    get new_admin_season_url
    assert_response :success
  end

  test "should create season for admin users" do
    login_as(@admin)
    assert_difference("Season.count") do
      post admin_seasons_url, params: {
        season: {
          name: "New Season",
          description: "A new season description",
          active: false,
          started_at: 1.day.ago,
          transition_ends_at: 1.day.ago + 7.days
        }
      }
    end

    assert_redirected_to admin_season_url(Season.last)
  end

  test "should show season for admin users" do
    login_as(@admin)
    get admin_season_url(@season)
    assert_response :success
  end

  test "should get edit for admin users" do
    login_as(@admin)
    get edit_admin_season_url(@season)
    assert_response :success
  end

  test "should update season for admin users" do
    login_as(@admin)
    patch admin_season_url(@season), params: {
      season: {
        name: "Updated Season",
        description: "Updated description"
      }
    }
    assert_redirected_to admin_season_url(@season)
    @season.reload
    assert_equal "Updated Season", @season.name
  end

  test "should destroy season for admin users" do
    login_as(@admin)
    assert_difference("Season.count", -1) do
      delete admin_season_url(@season)
    end

    assert_redirected_to admin_seasons_url
  end

  private

  def login_as(user)
    post session_url, params: { email_address: user.email_address, password: "password" }
  end
end

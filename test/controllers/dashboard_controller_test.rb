require "test_helper"

class DashboardControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @manager = @user.manager || @user.ensure_manager
  end

  test "should redirect unauthenticated users to login" do
    get dashboard_url
    assert_redirected_to new_session_path
  end

  test "should show dashboard for authenticated users" do
    sign_in_as(@user)
    get dashboard_url
    assert_response :success
    assert_select "h1", "Dashboard"
  end

  test "should redirect to dashboard after login" do
    post session_url, params: { email_address: @user.email_address, password: "password" }
    assert_redirected_to dashboard_url
  end
end

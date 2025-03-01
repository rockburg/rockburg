require "test_helper"

class PagesControllerTest < ActionDispatch::IntegrationTest
  test "should get home" do
    get root_url
    assert_response :success
    assert_select "h1", "Welcome to Rockburg"
  end

  test "should get about" do
    get about_url
    assert_response :success
    assert_select "h1", "About Rockburg"
  end

  test "should get privacy" do
    get privacy_url
    assert_response :success
    assert_select "h1", "Privacy Policy"
  end

  test "should get terms" do
    get terms_url
    assert_response :success
    assert_select "h1", "Terms of Service"
  end
end

require "test_helper"

class RegistrationsControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get new_registration_url
    assert_response :success
  end

  test "should create user" do
    assert_difference("User.count") do
      post registration_url, params: { user: { email_address: "new_user@example.com", password: "password", password_confirmation: "password" } }
    end

    assert_redirected_to dashboard_url
    assert_equal "Welcome to Rockburg! Your account has been created successfully.", flash[:notice]
  end

  test "should not create user with invalid parameters" do
    assert_no_difference("User.count") do
      post registration_url, params: { user: { email_address: "", password: "password", password_confirmation: "different" } }
    end

    assert_response :unprocessable_entity
  end
end

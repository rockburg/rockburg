require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "should be valid with valid attributes" do
    user = User.new(email_address: "test@example.com", password: "password", password_confirmation: "password")
    assert user.valid?
  end

  test "should not be valid without an email" do
    user = User.new(password: "password", password_confirmation: "password")
    assert_not user.valid?
  end

  test "should not be valid with an invalid email format" do
    user = User.new(email_address: "invalid", password: "password", password_confirmation: "password")
    assert_not user.valid?
  end

  test "should not be valid with a password less than 6 characters" do
    user = User.new(email_address: "test@example.com", password: "short", password_confirmation: "short")
    assert_not user.valid?
  end

  test "should not be valid with mismatched password confirmation" do
    user = User.new(email_address: "test@example.com", password: "password", password_confirmation: "different")
    assert_not user.valid?
  end

  test "should authenticate a user with correct credentials" do
    user = User.create(email_address: "test@example.com", password: "password", password_confirmation: "password")
    assert user.authenticate("password")
  end

  test "should not authenticate a user with incorrect credentials" do
    user = User.create(email_address: "test@example.com", password: "password", password_confirmation: "password")
    assert_not user.authenticate("wrong_password")
  end

  # Admin functionality tests
  test "user should default to non-admin" do
    user = User.create(email_address: "test@example.com", password: "password", password_confirmation: "password")
    assert_not user.admin?
  end

  test "admin? should return true for admin users" do
    user = User.create(email_address: "admin@example.com", password: "password", password_confirmation: "password", admin: true)
    assert user.admin?
  end
end

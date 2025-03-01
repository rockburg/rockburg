require "application_system_test_case"

class HeaderTest < ApplicationSystemTestCase
  test "displays manager level and budget in header when signed in" do
    # Create a user and manager
    user = users(:one)
    manager = Manager.create!(
      user: user,
      budget: 5000.00,
      level: 2,
      xp: 0,
      skill_points: 0,
      traits: {},
      nano_id: "test123"
    )

    # Visit home page
    visit root_path

    # Sign in
    click_on "Sign in"

    # Fill in the form
    within("form") do
      fill_in :email_address, with: user.email_address
      fill_in :password, with: "password"
      click_button "Sign in"
    end

    # Debug: Print the page HTML
    puts page.html

    # Debug: Check if we're signed in
    puts "Current user: #{Current.user.inspect}"
    puts "Current manager: #{Current.user&.manager.inspect}"

    # Now we should see the manager info in the header
    within("header") do
      assert_text "Level 2"
      assert_text "$5,000.00"
    end
  end
end

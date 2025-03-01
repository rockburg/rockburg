require "test_helper"

class ManagerInfoTest < ActionView::TestCase
  test "renders manager level and budget when manager is present" do
    # Create a user with a manager
    user = users(:one)
    manager = user.manager || user.ensure_manager
    manager.update(level: 3, budget: 7500)

    # Set Current.user
    Current.user = user

    # Render the partial
    render partial: "shared/manager_info"

    # Check that the manager info is rendered correctly
    assert_select "span", text: "Level 3"
    assert_select "span", text: "$7,500.00"

    # Clean up
    Current.reset
  end

  test "renders nothing when manager is not present" do
    # Set Current.user to nil
    Current.reset

    # Render the partial
    render partial: "shared/manager_info"

    # Check that nothing is rendered
    assert_select "div", count: 0
  end
end

require "test_helper"
require "rake"

class DevRakeTest < ActiveSupport::TestCase
  setup do
    # Load the rake tasks
    Rockburg::Application.load_tasks if Rake::Task.tasks.empty?
  end

  test "reset task exists" do
    assert Rake::Task.task_defined?("dev:reset"), "dev:reset task should exist"
  end

  test "regenerate_venues task exists" do
    assert Rake::Task.task_defined?("dev:regenerate_venues"), "dev:regenerate_venues task should exist"
  end

  test "regenerate_artists task exists" do
    assert Rake::Task.task_defined?("dev:regenerate_artists"), "dev:regenerate_artists task should exist"
  end
end

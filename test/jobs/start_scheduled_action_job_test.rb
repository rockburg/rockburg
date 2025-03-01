require "test_helper"

class StartScheduledActionJobTest < ActiveJob::TestCase
  setup do
    @artist = Artist.create!(
      name: "Test Artist",
      genre: "Rock",
      energy: 100,
      talent: 70
    )

    @scheduled_action = @artist.scheduled_actions.create!(
      activity_type: "practice",
      start_at: 1.hour.from_now
    )
  end

  test "starts the scheduled action at the specified time" do
    assert_changes -> { @artist.reload.current_action }, from: nil, to: "practice" do
      StartScheduledActionJob.perform_now(@scheduled_action.id)
    end

    # The scheduled action should be removed after processing
    assert_nil ScheduledAction.find_by(id: @scheduled_action.id)
  end

  test "ignores invalid scheduled action ids" do
    assert_no_changes -> { @artist.reload.current_action } do
      StartScheduledActionJob.perform_now(9999)
    end
  end

  test "does not start action if artist is already busy" do
    # Make the artist busy with an existing action
    @artist.start_activity!("record")

    assert_no_changes -> { @artist.reload.current_action } do
      StartScheduledActionJob.perform_now(@scheduled_action.id)
    end

    # The scheduled action should still be removed
    assert_nil ScheduledAction.find_by(id: @scheduled_action.id)
  end
end

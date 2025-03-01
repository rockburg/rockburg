class StartScheduledActionJob < ApplicationJob
  queue_as :default

  def perform(scheduled_action_id)
    # Find the scheduled action
    scheduled_action = ScheduledAction.find_by(id: scheduled_action_id)
    return unless scheduled_action

    artist = scheduled_action.artist
    activity_type = scheduled_action.activity_type

    # Log the scheduled action execution
    Rails.logger.info "Starting scheduled action '#{activity_type}' for artist #{artist.id} (#{artist.name})"

    # Check if artist is already busy
    if artist.busy?
      Rails.logger.warn "Cannot start scheduled action: Artist #{artist.id} is already busy"
      scheduled_action.destroy
      return
    end

    # Start the activity
    if artist.start_activity!(activity_type)
      Rails.logger.info "Successfully started scheduled action '#{activity_type}' for artist #{artist.id}"
    else
      Rails.logger.warn "Failed to start scheduled action '#{activity_type}' for artist #{artist.id}"
    end

    # Remove the scheduled action as it's now been processed
    scheduled_action.destroy
  end
end

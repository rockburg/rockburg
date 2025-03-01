class CompleteArtistActionJob < ApplicationJob
  queue_as :default

  def perform(artist_id)
    artist = Artist.find_by(id: artist_id)
    return unless artist

    # Only complete the action if it's past the end time or within a reasonable buffer (30 seconds)
    if artist.action_ends_at.present? && (Time.current >= artist.action_ends_at || Time.current >= artist.action_ends_at - 30.seconds)
      # Log the action completion
      Rails.logger.info "Completing action '#{artist.current_action}' for artist #{artist.id} (#{artist.name})"

      # Complete the action
      result = artist.complete_activity!

      # Log the result
      if result
        Rails.logger.info "Action '#{artist.current_action}' completed successfully for artist #{artist.id}"
      else
        Rails.logger.warn "Failed to complete action for artist #{artist.id}"
      end
    else
      # If the action end time was changed, reschedule the job
      if artist.action_ends_at.present? && artist.action_ends_at > Time.current
        wait_time = [ (artist.action_ends_at - Time.current).to_i, 1 ].max.seconds
        self.class.set(wait: wait_time).perform_later(artist_id)
      end
    end
  end
end

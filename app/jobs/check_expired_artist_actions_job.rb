class CheckExpiredArtistActionsJob < ApplicationJob
  queue_as :default

  def perform
    # Find artists with expired actions (end time in the past)
    expired_actions = Artist.where.not(current_action: nil)
                           .where.not(action_ends_at: nil)
                           .where("action_ends_at < ?", Time.current)

    if expired_actions.any?
      Rails.logger.info "Found #{expired_actions.count} expired artist actions"

      expired_actions.each do |artist|
        Rails.logger.info "Completing expired action '#{artist.current_action}' for artist #{artist.id} (#{artist.name})"

        # Complete the action
        result = artist.complete_activity!

        if result
          Rails.logger.info "Successfully completed expired action for artist #{artist.id}"
        else
          Rails.logger.warn "Failed to complete expired action for artist #{artist.id}"
        end
      end
    else
      Rails.logger.info "No expired artist actions found"
    end
  end
end

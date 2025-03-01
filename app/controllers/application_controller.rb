class ApplicationController < ActionController::Base
  include Authentication
  include NanoIdFindable
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  private

  def require_current_user
    unless Current.user
      redirect_to new_session_path, alert: "You must be logged in to perform this action."
    end
  end
end

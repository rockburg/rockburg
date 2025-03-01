class ApplicationController < ActionController::Base
  include Authentication
  include NanoIdFindable
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  helper_method :current_manager

  private

  def require_current_user
    unless Current.user
      redirect_to new_session_path, alert: "You must be logged in to perform this action."
    end
  end

  def require_current_manager
    unless Current.user&.manager
      redirect_to root_path, alert: "You need to have a manager profile to access this page"
    end

    # Set Current.manager if not already set
    Current.manager ||= Current.user.manager
  end

  def current_manager
    Current.manager
  end
end

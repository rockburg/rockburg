module ManagerAuthentication
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_manager!
    helper_method :current_manager
  end

  private
    def authenticate_manager!
      unless authenticated?
        redirect_to new_session_path
        return
      end

      unless Current.user&.manager
        flash[:alert] = "You need to have a manager profile to access this page"
        redirect_to root_path
      end
    end

    def current_manager
      @current_manager ||= Current.user&.manager
    end
end

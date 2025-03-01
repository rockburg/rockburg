module AdminAuthentication
  extend ActiveSupport::Concern

  included do
    before_action :require_admin

    class_attribute :unauthenticated_actions
    self.unauthenticated_actions = []
  end

  class_methods do
    def allow_unauthenticated_access(options = {})
      if options[:only].present?
        self.unauthenticated_actions = Array(options[:only]).map(&:to_s)
      end
    end
  end

  private
    def require_admin
      return if action_name.in?(unauthenticated_actions.map(&:to_s))

      unless authenticated?
        redirect_to new_session_path
        return
      end

      if Current.user.nil? || !Current.user.admin?
        flash[:alert] = "You don't have permission to access that page"
        redirect_to root_path
      end
    end
end

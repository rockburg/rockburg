module AdminAuthentication
  extend ActiveSupport::Concern

  included do
    before_action :require_admin
  end

  private
    def require_admin
      unless Current.user&.admin?
        flash[:alert] = "You don't have permission to access that page"
        redirect_to root_path
      end
    end
end

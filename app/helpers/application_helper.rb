module ApplicationHelper
  def current_season
    @current_season ||= Season.current
  end

  # Helper to get the current manager
  def current_manager
    @current_manager ||= Current.user&.manager
  end
end

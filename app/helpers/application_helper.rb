module ApplicationHelper
  def current_season
    @current_season ||= Season.current
  end
end

class Admin::DashboardController < ApplicationController
  include AdminAuthentication

  def index
    @seasons_count = Season.count
    @active_season = Season.find_by(active: true)
  end
end

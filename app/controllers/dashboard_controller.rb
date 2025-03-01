class DashboardController < ApplicationController
  include ManagerAuthentication
  before_action :check_for_season

  def index
    @artists = current_manager.artists.order("name ASC")

    # Get upcoming performances for the manager's artists
    @upcoming_performances = current_manager.upcoming_performances.limit(5)

    # Get recent performances for the manager's artists
    @past_performances = current_manager.past_performances.limit(5)

    # Get the active season
    @active_season = Season.active.first

    # To add venue statistics to the dashboard
    # This will be rendered with the partial we created
  end

  def recalculate_venue_stats
    # Only allow admins to recalculate stats
    if current_manager.admin?
      active_season = Season.active.first

      if active_season
        VenueStatsService.calculate_for_season(active_season)
        flash[:notice] = "Venue statistics have been recalculated"
      else
        flash[:alert] = "No active season found"
      end
    else
      flash[:alert] = "You don't have permission to perform this action"
    end

    redirect_to dashboard_path
  end

  private

  def check_for_season
    redirect_to welcome_path if Season.active.none?
  end
end

class Admin::DashboardController < ApplicationController
  include AdminAuthentication

  def index
    @seasons_count = Season.count
    @active_season = Season.find_by(active: true)
  end

  def regenerate_venues
    venue_count = params[:count].present? ? params[:count].to_i : 25

    # Queue the job
    RegenerateVenuesJob.perform_later(venue_count)

    # Set a flash message
    flash[:notice] = "Venue regeneration has been queued with count: #{venue_count}"

    # Redirect back to admin dashboard
    redirect_to admin_root_path
  end
end

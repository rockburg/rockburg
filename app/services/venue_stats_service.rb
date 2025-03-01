class VenueStatsService
  # Calculates venue statistics for a given season
  def self.calculate_for_season(season)
    stats = {
      venue_count: Venue.count,
      performances_by_tier: {},
      revenue_by_tier: {},
      most_popular_venues: []
    }

    # Group venues by tier
    venues_by_tier = Venue.all.group_by(&:tier)

    # Calculate stats for each tier
    (1..3).each do |tier|
      venues = venues_by_tier[tier] || []
      tier_performances = Performance.where(venue_id: venues.map(&:id))
                                     .where(status: "completed")

      successful_performances = tier_performances.count
      total_revenue = tier_performances.sum(:net_revenue)
      avg_attendance_pct = tier_performances.any? ?
        (tier_performances.sum(:attendance).to_f / tier_performances.sum { |p| p.venue.capacity }) * 100 : 0

      stats[:performances_by_tier][tier] = {
        venues: venues.count,
        performances: successful_performances,
        avg_attendance_percentage: avg_attendance_pct.round(2),
        total_revenue: total_revenue.round(2)
      }

      stats[:revenue_by_tier][tier] = total_revenue.round(2)
    end

    # Get top venues by performance count
    top_venues = Performance.where(status: "completed")
                           .group(:venue_id)
                           .select("venue_id, COUNT(*) as performance_count, SUM(attendance) as total_attendance, SUM(net_revenue) as total_revenue")
                           .order("performance_count DESC, total_revenue DESC")
                           .limit(5)

    stats[:most_popular_venues] = top_venues.map do |result|
      venue = Venue.find_by(id: result.venue_id)
      next unless venue

      {
        id: venue.id,
        name: venue.name,
        tier: venue.tier,
        performance_count: result.performance_count,
        avg_attendance: (result.total_attendance.to_f / result.performance_count).round(0),
        total_revenue: result.total_revenue.round(2)
      }
    end.compact

    # Add timestamp
    stats[:generated_at] = Time.current

    # Update the season with the stats
    season.update(venue_stats: stats)

    stats
  end

  # Updates venue stats for the active season
  def self.update_active_season_stats
    active_season = Season.active.first
    calculate_for_season(active_season) if active_season
  end

  # Update stats when a venue regeneration occurs
  def self.after_venue_regeneration
    active_season = Season.active.first
    return unless active_season

    # If the season doesn't have stats yet, create them
    if active_season.venue_stats.blank?
      calculate_for_season(active_season)
    else
      # Otherwise just update the venue count
      stats = active_season.venue_stats
      stats[:venue_count] = Venue.count
      active_season.update(venue_stats: stats)
    end
  end
end

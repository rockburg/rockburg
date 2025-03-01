class AddVenueStatsToSeason < ActiveRecord::Migration[8.0]
  def change
    add_column :seasons, :venue_stats, :jsonb
  end
end

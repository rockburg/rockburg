class AddActionTimingToArtists < ActiveRecord::Migration[8.0]
  def change
    add_column :artists, :current_action, :string
    add_column :artists, :action_started_at, :datetime
    add_column :artists, :action_ends_at, :datetime
  end
end

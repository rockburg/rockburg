class AddDeactivatedAtToSeasons < ActiveRecord::Migration[8.0]
  def change
    add_column :seasons, :deactivated_at, :datetime
  end
end

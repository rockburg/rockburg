class AddActivatedAtToSeasons < ActiveRecord::Migration[8.0]
  def change
    add_column :seasons, :activated_at, :datetime
  end
end

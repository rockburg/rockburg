class AddManagerXpGainToPerformances < ActiveRecord::Migration[8.0]
  def change
    add_column :performances, :manager_xp_gain, :integer
  end
end

class AddMaxEnergyToArtists < ActiveRecord::Migration[8.0]
  def change
    add_column :artists, :max_energy, :integer, default: 100, null: false
  end
end

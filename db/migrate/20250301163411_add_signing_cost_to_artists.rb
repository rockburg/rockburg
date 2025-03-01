class AddSigningCostToArtists < ActiveRecord::Migration[8.0]
  def change
    add_column :artists, :signing_cost, :decimal, precision: 10, scale: 2, default: 0.0, null: false
    add_index :artists, :signing_cost
  end
end

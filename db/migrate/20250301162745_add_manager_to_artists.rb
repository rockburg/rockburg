class AddManagerToArtists < ActiveRecord::Migration[8.0]
  def change
    add_reference :artists, :manager, null: true, foreign_key: true
    add_column :artists, :cost, :decimal, precision: 10, scale: 2, default: 0.0, null: false
    add_column :artists, :signing_cost, :decimal, precision: 10, scale: 2, default: 0.0, null: false
    add_column :artists, :revenue, :decimal, precision: 10, scale: 2, default: 0.0, null: false

    add_index :artists, :cost
    add_index :artists, :revenue
  end
end

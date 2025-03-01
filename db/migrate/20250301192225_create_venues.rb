class CreateVenues < ActiveRecord::Migration[8.0]
  def change
    create_table :venues do |t|
      t.string :name, null: false
      t.integer :capacity, null: false
      t.decimal :booking_cost, precision: 10, scale: 2, null: false, default: 0
      t.integer :prestige, null: false, default: 1
      t.integer :tier, null: false, default: 1
      t.string :description
      t.jsonb :preferences, default: {}

      t.timestamps
    end

    add_index :venues, :tier
    add_index :venues, :capacity
  end
end

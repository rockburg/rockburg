class CreatePerformances < ActiveRecord::Migration[8.0]
  def change
    create_table :performances do |t|
      t.references :artist, null: false, foreign_key: true
      t.references :venue, null: false, foreign_key: true
      t.datetime :scheduled_for, null: false
      t.integer :duration_minutes, null: false, default: 60
      t.decimal :ticket_price, precision: 10, scale: 2, null: false, default: 0
      t.integer :attendance, default: 0
      t.string :status, null: false, default: "scheduled"
      t.decimal :gross_revenue, precision: 10, scale: 2, default: 0
      t.decimal :venue_cut, precision: 10, scale: 2, default: 0
      t.decimal :expenses, precision: 10, scale: 2, default: 0
      t.decimal :net_revenue, precision: 10, scale: 2, default: 0
      t.decimal :merch_revenue, precision: 10, scale: 2, default: 0
      t.integer :skill_gain, default: 0
      t.integer :popularity_gain, default: 0
      t.jsonb :details, default: {}

      t.timestamps
    end

    add_index :performances, :scheduled_for
    add_index :performances, :status
  end
end

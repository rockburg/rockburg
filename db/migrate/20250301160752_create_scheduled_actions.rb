class CreateScheduledActions < ActiveRecord::Migration[8.0]
  def change
    create_table :scheduled_actions do |t|
      t.string :activity_type
      t.datetime :start_at
      t.references :artist, null: false, foreign_key: true

      t.timestamps
    end
  end
end

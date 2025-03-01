class CreateSeasons < ActiveRecord::Migration[8.0]
  def change
    create_table :seasons do |t|
      t.string :name, null: false
      t.boolean :active, default: false, null: false
      t.datetime :transition_ends_at
      t.datetime :started_at
      t.datetime :ended_at
      t.jsonb :genre_trends, default: {}, null: false
      t.jsonb :settings, default: {}, null: false
      t.text :description

      t.timestamps
    end

    add_index :seasons, :active
  end
end

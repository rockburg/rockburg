class CreateManagers < ActiveRecord::Migration[8.0]
  def change
    create_table :managers do |t|
      t.references :user, null: false, foreign_key: true
      t.decimal :budget, precision: 10, scale: 2, default: 1000.00, null: false
      t.integer :level, default: 1, null: false
      t.integer :xp, default: 0, null: false
      t.integer :skill_points, default: 0, null: false
      t.jsonb :traits, default: {}, null: false
      t.string :nano_id

      t.timestamps
    end

    add_index :managers, :nano_id, unique: true
    add_index :managers, :level
    add_index :managers, :budget
  end
end

class CreateArtists < ActiveRecord::Migration[8.0]
  def change
    create_table :artists do |t|
      t.string :name, null: false
      t.string :genre, null: false
      t.integer :energy, null: false
      t.integer :talent, null: false
      t.integer :skill, default: 0, null: false
      t.integer :popularity, default: 0, null: false
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end

    add_index :artists, :name
    add_index :artists, :popularity
  end
end

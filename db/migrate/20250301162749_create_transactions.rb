class CreateTransactions < ActiveRecord::Migration[8.0]
  def change
    create_table :transactions do |t|
      t.references :manager, null: false, foreign_key: true
      t.decimal :amount, precision: 10, scale: 2, null: false
      t.string :description, null: false
      t.string :transaction_type, null: false
      t.references :artist, null: true, foreign_key: true
      t.string :nano_id

      t.timestamps
    end

    add_index :transactions, :nano_id, unique: true
    add_index :transactions, :transaction_type
    add_index :transactions, :created_at
  end
end

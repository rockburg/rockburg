class AddIndexToSigningCost < ActiveRecord::Migration[8.0]
  def change
    add_index :artists, :signing_cost
  end
end

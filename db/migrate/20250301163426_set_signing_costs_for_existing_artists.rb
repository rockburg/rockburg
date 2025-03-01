class SetSigningCostsForExistingArtists < ActiveRecord::Migration[8.0]
  def up
    # Set signing costs for existing artists based on talent and required level
    # This ensures all existing artists have appropriate signing costs
    Artist.find_each do |artist|
      # Calculate signing cost based on talent and required level
      base_cost = 1000
      talent_multiplier = (artist.talent / 10.0) + 0.5
      level_multiplier = artist.required_level * 0.5

      signing_cost = (base_cost * talent_multiplier * level_multiplier).round(2)

      # Update the artist with the calculated signing cost
      artist.update_column(:signing_cost, signing_cost)
    end
  end

  def down
    # Reset all signing costs to 0 if rolling back
    Artist.update_all(signing_cost: 0.0)
  end
end

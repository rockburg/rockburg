class AddNanoIdToExistingSeasons < ActiveRecord::Migration[8.0]
  def up
    Season.find_each do |season|
      # Skip if nano_id is already set
      next if season.nano_id.present?

      # Generate a unique nano_id
      loop do
        season.nano_id = Nanoid.generate(size: 16, alphabet: "0123456789abcdefghijklmnopqrstuvwxyz")
        break unless Season.exists?(nano_id: season.nano_id)
      end

      # Save the season with the new nano_id
      season.save(validate: false)
    end
  end

  def down
    # This migration is not reversible
  end
end

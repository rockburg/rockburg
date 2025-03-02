class RegenerateArtistEnergyJob < ApplicationJob
  queue_as :default

  # Amount of energy to regenerate per interval
  ENERGY_REGEN_AMOUNT = 2

  def perform
    # Find all artists who are not busy (no current action)
    idle_artists = Artist.where(current_action: nil)

    if idle_artists.any?
      Rails.logger.info "Regenerating energy for #{idle_artists.count} idle artists"

      idle_artists.each do |artist|
        # Skip artists who already have max energy
        next if artist.energy >= 100

        # Calculate energy gain based on artist traits
        energy_gain = ENERGY_REGEN_AMOUNT

        # Apply resilience trait bonus if present
        if artist.traits["resilience"].present?
          resilience_bonus = (artist.traits["resilience"] / 25.0).ceil
          energy_gain += resilience_bonus
        end

        # Cap energy at 100
        new_energy = [ artist.energy + energy_gain, 100 ].min

        # Only update if there's an actual change
        if new_energy > artist.energy
          artist.update(energy: new_energy)
          Rails.logger.debug "Artist #{artist.id} (#{artist.name}) energy increased from #{artist.energy - energy_gain} to #{artist.energy}"
        end
      end
    else
      Rails.logger.info "No idle artists found for energy regeneration"
    end
  end
end

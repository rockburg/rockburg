class GenerateNamesForExistingManagers < ActiveRecord::Migration[8.0]
  def up
    # Lists of words to use for name generation (same as in HasGeneratedName concern)
    adjectives = [
      "Ambitious", "Brilliant", "Creative", "Dynamic", "Eccentric",
      "Funky", "Groovy", "Harmonious", "Innovative", "Jazzy",
      "Keen", "Legendary", "Melodic", "Nifty", "Optimistic",
      "Passionate", "Quirky", "Rhythmic", "Stellar", "Trendy",
      "Upbeat", "Vibrant", "Whimsical", "Zealous", "Acoustic",
      "Bouncy", "Cosmic", "Dazzling", "Energetic", "Flashy",
      "Glittery", "Hypnotic", "Iconic", "Jumpin'", "Kaleidoscopic",
      "Luminous", "Magnetic", "Nostalgic", "Otherworldly", "Psychedelic",
      "Radiant", "Soulful", "Thunderous", "Ultramodern", "Velvety"
    ]

    nouns = [
      "Maestro", "Virtuoso", "Prodigy", "Genius", "Visionary",
      "Guru", "Wizard", "Dynamo", "Mastermind", "Sensation",
      "Pioneer", "Luminary", "Phenomenon", "Maverick", "Superstar",
      "Champion", "Trailblazer", "Innovator", "Legend", "Rockstar",
      "Impresario", "Mogul", "Tycoon", "Architect", "Conductor",
      "Producer", "Director", "Orchestrator", "Strategist", "Curator",
      "Composer", "Arranger", "Catalyst", "Amplifier", "Resonator",
      "Headliner", "Performer", "Entertainer", "Soloist", "Vocalist"
    ]

    # Generate names for existing managers
    Manager.where(name: nil).find_each do |manager|
      adjective = adjectives.sample
      noun = nouns.sample
      manager.update_column(:name, "#{adjective} #{noun}")
    end
  end

  def down
    # No need to revert as we're just adding data
  end
end

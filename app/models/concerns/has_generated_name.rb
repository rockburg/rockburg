module HasGeneratedName
  extend ActiveSupport::Concern

  # Lists of words to use for name generation
  ADJECTIVES = [
    "Ambitious", "Brilliant", "Creative", "Dynamic", "Eccentric",
    "Funky", "Groovy", "Harmonious", "Innovative", "Jazzy",
    "Keen", "Legendary", "Melodic", "Nifty", "Optimistic",
    "Passionate", "Quirky", "Rhythmic", "Stellar", "Trendy",
    "Upbeat", "Vibrant", "Whimsical", "Zealous", "Acoustic",
    "Bouncy", "Cosmic", "Dazzling", "Energetic", "Flashy",
    "Glittery", "Hypnotic", "Iconic", "Jumpin'", "Kaleidoscopic",
    "Luminous", "Magnetic", "Nostalgic", "Otherworldly", "Psychedelic",
    "Radiant", "Soulful", "Thunderous", "Ultramodern", "Velvety",
    "Wondrous", "Xtraordinary", "Yearning", "Zestful", "Authentic",
    "Blazing", "Charismatic", "Dreamy", "Ethereal", "Fierce",
    "Galactic", "Heavenly", "Intoxicating", "Jubilant", "Kinetic",
    "Luscious", "Mystical", "Neon", "Organic", "Pulsating",
    "Quantum", "Resonant", "Shimmering", "Transcendent", "Unstoppable",
    "Vivacious", "Wild", "Xenial", "Youthful", "Zany",
    "Astounding", "Bombastic", "Celestial", "Daring", "Electrifying",
    "Fantastical", "Glamorous", "Heroic", "Illuminating", "Jubilant",
    "Kaleidoscopic", "Liberating", "Majestic", "Nebulous", "Opulent",
    "Prismatic", "Quintessential", "Revolutionary", "Scintillating", "Tantalizing",
    "Unbound", "Victorious", "Wicked", "Xenodochial", "Yowza",
    "Zigzagging", "Audacious", "Breathtaking", "Captivating", "Dazzling",
    "Exhilarating", "Flamboyant", "Grandiose", "Hyperdimensional", "Illustrious",
    "Jaw-dropping", "Kinesthetic", "Luxurious", "Mesmerizing", "Nuanced",
    "Outrageous", "Phenomenal", "Quixotic", "Ravishing", "Sensational",
    "Titanic", "Unreal", "Volcanic", "Wonderstruck", "Xenogenic",
    "Yearning", "Zenith", "Astonishing", "Boisterous", "Chromatic"
  ].freeze

  NOUNS = [
    "Maestro", "Virtuoso", "Prodigy", "Genius", "Visionary",
    "Guru", "Wizard", "Dynamo", "Mastermind", "Sensation",
    "Pioneer", "Luminary", "Phenomenon", "Maverick", "Superstar",
    "Champion", "Trailblazer", "Innovator", "Legend", "Rockstar",
    "Impresario", "Mogul", "Tycoon", "Architect", "Conductor",
    "Producer", "Director", "Orchestrator", "Strategist", "Curator",
    "Composer", "Arranger", "Catalyst", "Amplifier", "Resonator",
    "Headliner", "Performer", "Entertainer", "Soloist", "Vocalist",
    "Instrumentalist", "Beatmaker", "Songwriter", "Lyricist", "Hitmaker",
    "Bandleader", "Frontman", "Diva", "Crooner", "Troubadour",
    "Virtuoso", "Improviser", "Percussionist", "Bassist", "Guitarist",
    "Keyboardist", "Drummer", "Saxophonist", "Trumpeter", "Violinist",
    "Promoter", "Agent", "Manager", "Executive", "Entrepreneur",
    "Magnate", "Dealmaker", "Negotiator", "Networker", "Influencer",
    "Trendsetter", "Tastemaker", "Kingpin", "Heavyweight", "Powerhouse",
    "Rainmaker", "Moneymaker", "Profiteer", "Investor", "Financier",
    "Publicist", "Marketer", "Advertiser", "Broadcaster", "Announcer",
    "Emcee", "Host", "Presenter", "Interviewer", "Commentator",
    "Critic", "Reviewer", "Analyst", "Theorist", "Historian",
    "Archivist", "Collector", "Connoisseur", "Aficionado", "Enthusiast",
    "Devotee", "Fanatic", "Zealot", "Disciple", "Follower",
    "Idol", "Icon", "Celebrity", "Star", "Headliner",
    "Entertainer", "Performer", "Showstopper", "Crowd-pleaser", "Charmer",
    "Enchanter", "Mesmerizer", "Hypnotist", "Spellbinder", "Captivator",
    "Seducer", "Tempter", "Tantalizer", "Teaser", "Provocateur",
    "Stimulator", "Activator", "Energizer", "Motivator", "Inspirer",
    "Muse", "Influence", "Inspiration", "Originator", "Creator",
    "Inventor", "Designer", "Developer", "Builder", "Constructor",
    "Engineer", "Technician", "Specialist", "Expert", "Authority",
    "Master", "Adept", "Virtuoso", "Savant", "Prodigy"
  ].freeze

  included do
    before_create :generate_name, if: -> { name.blank? }
  end

  private

  # Generate a random name by combining an adjective and a noun
  def generate_name
    # Filter out adjectives and nouns with special characters
    valid_adjectives = ADJECTIVES.select { |adj| adj.match?(/\A[\w']+\z/) }
    valid_nouns = NOUNS.select { |noun| noun.match?(/\A[\w']+\z/) }

    adjective = valid_adjectives.sample
    noun = valid_nouns.sample
    self.name = "#{adjective} #{noun}"
  end
end

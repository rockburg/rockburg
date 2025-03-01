class ArtistGeneratorService
  class GenerationError < StandardError; end
  class InvalidArtistDataError < StandardError; end

  require "securerandom"

  REQUIRED_FIELDS = %w[name genre energy talent].freeze

  def self.generate(user = nil)
    # Refactored to use batch generation with count = 1
    new(user).generate_artist
  end

  def self.generate_batch(count = 10, user = nil)
    new(user).generate_artist_batch(count)
  end

  # For backward compatibility with tests
  def self.generate_artist(attributes = {})
    artist_data = {
      "name" => attributes[:name] || "Test Artist",
      "genre" => attributes[:genre] || "Rock",
      "energy" => attributes[:energy] || 100,
      "talent" => attributes[:talent] || 50
    }

    new.create_artist(artist_data)
  end

  def initialize(user = nil)
    @user = user
    @client = OpenAI::Client.new unless Rails.env.test?
  end

  def generate_artist
    # For tests, use the mocked data if available
    if Rails.env.test?
      begin
        artist_data = fetch_artist_data
        validate_artist_data(artist_data)
        return create_artist(artist_data)
      rescue StandardError => e
        raise GenerationError, "Failed to generate artist: #{e.message}"
      end
    end

    # For production, create a single artist
    generate_artist_batch(1).first
  end

  def generate_artist_batch(count)
    # For tests, use the mocked data if available
    if Rails.env.test?
      begin
        artist_data_batch = fetch_artist_batch_data(count)

        # Process the data into a usable format
        artist_data_batch = extract_artist_array(artist_data_batch)

        # Create artists
        artists = []
        artist_data_batch.each do |artist_data|
          validate_artist_data(artist_data)
          artists << create_artist(artist_data)
        end

        return artists
      rescue StandardError => e
        raise GenerationError, "Failed to generate artist batch: #{e.message}"
      end
    end

    # Get artist data from API
    artist_data_batch = fetch_artist_batch_data(count)

    # Process the data into a usable format
    artist_data_batch = extract_artist_array(artist_data_batch)

    # Always analyze affordability for all batches
    affordability_stats = analyze_batch_affordability(artist_data_batch)

    # More aggressive affordability adjustment: always adjust unless we have at least 50% affordable
    if affordability_stats[:affordable_percentage] < 50
      artist_data_batch = adjust_batch_for_affordability(artist_data_batch)

      # Log the adjustment
      Rails.logger.info("Adjusted batch for affordability: Before: #{affordability_stats[:affordable_percentage]}%, After: #{analyze_batch_affordability(artist_data_batch)[:affordable_percentage]}%")
    end

    # Create artists
    artists = []
    artist_data_batch.each do |artist_data|
      begin
        validate_artist_data(artist_data)
        artists << create_artist(artist_data)
      rescue => e
        Rails.logger.error("Error creating artist #{artist_data["name"]}: #{e.message}")
      end
    end

    # Log a summary of the results
    affordable_count = artists.count { |artist| is_affordable_for_new_player?(artist) }
    Rails.logger.info("Batch generation completed: #{artists.length}/#{artist_data_batch.length} artists created, #{affordable_count} affordable (#{(affordable_count.to_f / artists.length * 100).round(1)}%)")

    artists
  rescue InvalidArtistDataError => e
    Rails.logger.error("Invalid artist data batch: #{e.message}")
    raise
  rescue StandardError => e
    Rails.logger.error("Error generating artist batch: #{e.message}")
    raise GenerationError, "Failed to generate artist batch: #{e.message}"
  end

  private

  # Helper to extract artist array from various response formats
  def extract_artist_array(data)
    # Handle special case formats
    if data.is_a?(Array) && data.length == 2 && data[0].is_a?(String) && data[1].is_a?(Array)
      return data[1]
    end

    # Handle hash with artists key
    if data.is_a?(Hash) && data["artists"].is_a?(Array)
      return data["artists"]
    end

    # Handle other common formats
    if data.is_a?(Hash)
      # Look for arrays in common keys
      %w[artists profiles data].each do |key|
        return data[key] if data[key].is_a?(Array)
      end

      # Check all hash values for arrays
      data.each_value do |value|
        return value if value.is_a?(Array) && value.all? { |item| item.is_a?(Hash) }
      end

      # Single artist wrapped in hash
      return [ data ] if REQUIRED_FIELDS.all? { |field| data.key?(field) }
    end

    # Already an array of artist hashes
    return data if data.is_a?(Array) && data.all? { |item| item.is_a?(Hash) }

    # If we get here, format wasn't recognized
    raise InvalidArtistDataError, "Expected array of artist data, got: #{data.class}"
  end

  def fetch_artist_data
    # In test environment, this should be stubbed to return mock data
    if Rails.env.test?
      raise StandardError, "API Error" if @raise_error
      raise InvalidArtistDataError, "Missing required fields" if @invalid_data
      return {}
    end

    Rails.logger.info("Requesting artist from OpenAI API")

    response = @client.chat(
      parameters: {
        model: "gpt-4o-mini",
        messages: [
          { role: "system", content: system_prompt },
          { role: "user", content: batch_user_prompt(1) }
        ],
        temperature: 1.0,
        response_format: { type: "json_object" }
      }
    )

    # Parse the response
    raw_content = response.dig("choices", 0, "message", "content")

    begin
      parsed_data = JSON.parse(raw_content)
      # Extract the first artist from the batch
      artists = extract_artist_array(parsed_data)
      artists.first || {}
    rescue JSON::ParserError => e
      Rails.logger.error("Failed to parse JSON response: #{e.message}")
      raise InvalidArtistDataError, "Invalid data format returned from API"
    end
  end

  def fetch_artist_batch_data(count)
    # In test environment, this should be stubbed to return mock data
    return [] if Rails.env.test?

    Rails.logger.info("Requesting #{count} artists from OpenAI API")

    response = @client.chat(
      parameters: {
        model: "gpt-4o-mini",
        messages: [
          { role: "system", content: system_prompt },
          { role: "user", content: batch_user_prompt(count) }
        ],
        temperature: 1.0,
        response_format: { type: "json_object" }
      }
    )

    # Parse the response
    raw_content = response.dig("choices", 0, "message", "content")

    begin
      parsed_data = JSON.parse(raw_content)
      parsed_data
    rescue JSON::ParserError => e
      Rails.logger.error("Failed to parse JSON response: #{e.message}")
      raise InvalidArtistDataError, "Invalid data format returned from API"
    end
  end

  def validate_artist_data(data)
    # Ensure data is a hash
    unless data.is_a?(Hash)
      raise InvalidArtistDataError, "Artist data must be a hash, got #{data.class}"
    end

    # Check for missing required fields
    missing_fields = REQUIRED_FIELDS.select { |field| !data.key?(field) || data[field].nil? }
    unless missing_fields.empty?
      raise InvalidArtistDataError, "Missing required fields: #{missing_fields.join(', ')}"
    end

    # Validate numeric fields
    %w[energy talent].each do |field|
      value = data[field]

      # Try to convert string to integer if possible
      if value.is_a?(String) && value.match?(/^\d+$/)
        data[field] = value.to_i
        value = data[field]
      elsif value.is_a?(String) && value.match?(/^\d+\.\d+$/)
        data[field] = value.to_i # Convert float strings to integers
        value = data[field]
      elsif value.is_a?(Float)
        data[field] = value.to_i # Convert floats to integers
        value = data[field]
      end

      unless value.is_a?(Numeric) && value >= 0 && value <= 100
        raise InvalidArtistDataError, "#{field} must be a number between 0 and 100, got: #{value.inspect}"
      end
    end

    # Validate genre is a non-empty string
    if data["genre"].nil? || data["genre"].to_s.strip.empty?
      raise InvalidArtistDataError, "genre must be a non-empty string"
    end

    # Ensure genre is a string
    data["genre"] = data["genre"].to_s if data["genre"].present?

    # Validate required_level if provided
    if data.key?("required_level") && data["required_level"].present?
      value = data["required_level"]

      # Try to convert string to integer if possible
      if value.is_a?(String) && value.match?(/^\d+$/)
        data["required_level"] = value.to_i
        value = data["required_level"]
      elsif value.is_a?(String) && value.match?(/^\d+\.\d+$/)
        data["required_level"] = value.to_i # Convert float strings to integers
        value = data["required_level"]
      elsif value.is_a?(Float)
        data["required_level"] = value.to_i # Convert floats to integers
        value = data["required_level"]
      end

      unless value.is_a?(Numeric) && value >= 1 && value <= 5
        raise InvalidArtistDataError, "required_level must be a number between 1 and 5, got: #{value.inspect}"
      end
    end
  end

  def create_artist(data)
    data = data.with_indifferent_access

    # Ensure numeric fields are actually numeric
    %w[energy talent].each do |field|
      data[field] = data[field].to_i if data[field].present?
    end

    # Ensure genre is stored as a string
    data["genre"] = data["genre"].to_s if data["genre"].present?

    # Extract traits
    traits = extract_traits(data)

    # Determine required level
    required_level = if data["required_level"].present?
                       level = data["required_level"].to_i
                       (level >= 1 && level <= 5) ? level : calculate_required_level(data["talent"].to_i)
    else
                       calculate_required_level(data["talent"].to_i)
    end

    # Calculate skill based on talent and traits
    resilience_value = traits["resilience"].to_i
    discipline_value = traits["discipline"].to_i
    creativity_value = traits["creativity"].to_i

    # Base skill calculation
    base_skill = (data["talent"].to_i * 0.5).to_i +
                (discipline_value * 0.2).to_i +
                (creativity_value * 0.2).to_i +
                rand(1..[ (data["talent"].to_i * 0.1).to_i, 1 ].max)

    # Add bonus for exceptional talent
    base_skill += (data["talent"].to_i - 85) / 2 if data["talent"].to_i > 85

    # Cap skill based on talent tier
    max_starting_skill = case
    when data["talent"].to_i > 80 then 80
    when data["talent"].to_i > 60 then 70
    when data["talent"].to_i > 40 then 60
    else 50
    end
    base_skill = [ base_skill, max_starting_skill ].min

    # Calculate energy values
    max_energy = 100 + (resilience_value * 0.5).to_i + (required_level * 5)

    # Determine minimum energy percent based on resilience
    min_energy_percent = if resilience_value < 30
                           0.6 # 60% minimum for low resilience
    elsif resilience_value < 60
                           0.7 # 70% minimum for medium resilience
    else
                           0.8 # 80% minimum for high resilience
    end

    # Starting energy is a random value between minimum and maximum
    starting_energy = ((max_energy * min_energy_percent) + rand(0..(max_energy * (1 - min_energy_percent)).to_i)).to_i

    # Create the artist - no user or manager associated yet
    Artist.create!(
      name: data["name"],
      genre: data["genre"],
      energy: starting_energy,
      max_energy: max_energy,
      talent: data["talent"],
      skill: base_skill,
      popularity: (rand(0..20) + (data["talent"].to_i / 20.0)).to_i,
      background: data["background"] || data["bio"] || data["description"] || "",
      traits: traits,
      required_level: required_level,
      signing_cost: data["signing_cost"] || calculate_signing_cost(data["talent"], required_level),
      nano_id: SecureRandom.alphanumeric(10)
    )
  end

  # New helper method to calculate required level with more low-level artists
  def calculate_required_level(talent_value)
    return 1 if Rails.env.test?

    # Default weights strongly favoring level 1
    level_weights = [ 70, 20, 7, 2, 1 ]  # Percentages for levels 1-5

    # Less aggressive talent-based adjustment
    if talent_value > 90  # Only the most exceptional artists
      level_weights = [ 50, 25, 15, 7, 3 ]
    elsif talent_value > 75  # Very talented artists
      level_weights = [ 60, 25, 10, 4, 1 ]
    end

    # Use weighted random selection
    random = rand(1..100)
    cumulative = 0

    level = nil
    level_weights.each_with_index do |weight, index|
      cumulative += weight
      if random <= cumulative
        level = index + 1
        break
      end
    end

    # Return the level, or fallback to level 1
    level || 1
  end

  # Extract traits from artist data
  def extract_traits(data)
    traits = {}

    # Use provided traits if available
    if data["traits"].is_a?(Hash)
      traits = data["traits"].transform_keys(&:to_s)
    end

    # Ensure all trait fields exist with default values
    %w[charisma creativity discipline resilience].each do |trait|
      # Convert string values to integers if needed
      if traits[trait].is_a?(String) && traits[trait].match?(/^\d+$/)
        traits[trait] = traits[trait].to_i
      end

      # Set default values if missing
      traits[trait] ||= calculate_default_trait_value(data["talent"].to_i, trait)
    end

    # Ensure all traits are within valid range
    traits.each do |trait, value|
      traits[trait] = [ [ value.to_i, 1 ].max, 100 ].min
    end

    traits
  end

  # Calculate default trait value based on talent
  def calculate_default_trait_value(talent, trait_name)
    # Base value is related to talent
    base = (talent * 0.7).to_i

    # Add some randomness
    variance = (talent * 0.3).to_i
    base + rand(-variance..variance)
  end

  # Calculate signing cost based on talent and required level
  def calculate_signing_cost(talent, required_level)
    # Base cost calculation
    base_cost = (talent * 10) + (required_level * 100)

    # Add some randomness
    variance = (base_cost * 0.2).to_i
    base_cost += rand(-variance..variance)

    # Ensure minimum cost based on level
    min_cost = case required_level
    when 1 then 500
    when 2 then 1000
    when 3 then 2000
    when 4 then 3500
    else 5000
    end

    # Ensure maximum cost based on level
    max_cost = case required_level
    when 1 then 1500
    when 2 then 3000
    when 3 then 5000
    when 4 then 8000
    else 12000
    end

    # Clamp the cost between min and max
    [ [ base_cost, min_cost ].max, max_cost ].min
  end

  # Helper method to check if an artist is affordable for a new player
  def is_affordable_for_new_player?(artist_data)
    # For test data
    return true if Rails.env.test?

    # If it's already an Artist object
    if artist_data.is_a?(Artist)
      return artist_data.signing_cost.to_i <= 1000 && artist_data.required_level.to_i <= 1
    end

    # If it's a hash of artist data
    cost = artist_data["signing_cost"].to_i
    level = artist_data["required_level"].to_i

    # If signing_cost isn't specified, estimate it
    if cost == 0
      talent = artist_data["talent"].to_i
      level = level > 0 ? level : 1
      cost = calculate_signing_cost(talent, level)
    end

    # Check affordability criteria
    cost <= 1000 && (level <= 1 || level == 0)
  end

  # System prompt for generating artists
  def system_prompt
    <<~PROMPT
      You are an expert music industry AI that generates realistic artists for a music management game.
      You'll create varied and interesting artists with appropriate attributes based on the requirements.

      Each artist must have these attributes:
      - name: A realistic band or artist name appropriate to their genre
      - genre: A specific music genre (not just "rock" but "indie rock" or "post-punk")
      - energy: A value from 40-100 representing their current energy level
      - talent: A value from 1-100 representing their natural musical ability
      - required_level: Manager level needed to sign them (1-5)
      - traits: An object with these traits, each with values from 1-100:
        - charisma: Social skills and star quality
        - creativity: Songwriting and artistic innovation
        - discipline: Work ethic and consistency
        - resilience: Ability to handle setbacks
      - background: A brief 1-2 sentence backstory about the artist, slighly quirky and funny

      IMPORTANT TALENT DISTRIBUTION REQUIREMENTS:
      - The talent distribution should follow a realistic bell curve heavily weighted toward the lower end:
        - At least 60% of artists must have low talent (1-30 range)
        - Around 25% should have moderate talent (31-60 range)
        - Only 15% should have high talent (61-100 range)

      REQUIRED LEVEL DISTRIBUTION:
      - 80% of artists MUST be level 1 (always for artists with talent under 30)
      - 15% of artists should be level 2
      - 4% should be level 3
      - 1% should be level 4 or 5

      TALENT AND LEVEL CORRELATION:
      - Low talent artists (1-30) MUST ALWAYS be level 1
      - Medium talent artists (31-60) can be distributed across levels 1-3
      - High talent artists (61-100) can be distributed across levels 1-4

      AFFORDABILITY REQUIREMENTS:
      - Most artists should cost under $1,000 to sign (for new players with $1,000 budget)
      - NO artist with talent below 30 should cost more than $1,000
      - Many artists should be in the $800-$1,000 range for new players

      TRAIT BALANCE REQUIREMENTS:
      - Most artists should have a primary trait that's slightly higher than their others
      - Low talent artists (1-30) should generally have lower trait values (5-40 range)
      - Medium talent artists should have moderate trait values (20-60 range)
      - High talent artists can have higher trait values (30-80 range)
      - Very few artists should have exceptional traits (80-100)

      Output JSON only, no other text or formatting.
    PROMPT
  end

  # Replace the individual user_prompt with a batch_user_prompt that handles count=1
  def batch_user_prompt(count)
    <<~PROMPT
      Generate EXACTLY #{count} unique artist profiles for our music management game.

      IMPORTANT DISTRIBUTION REQUIREMENTS:
      - Follow the talent distribution in the system prompt
      - Ensure at least 60% of artists have talent in the 1-30 range
      - Only about 15% should have talent above 60
      - At least 80% should be level 1 (required for new players)

      AFFORDABILITY REQUIREMENTS:
      - At least 50% of artists must be affordable for new players (under $1,000 to sign)
      - All artists with talent under 30 must cost less than $1,000

      DIVERSITY REQUIREMENTS:
      - Include a wide variety of genres (rock, pop, hip-hop, electronic, country, etc.)
      - Mix of solo artists and bands
      - Varied trait combinations (some disciplined but not creative, etc.)
      - Different backgrounds and origin stories

      Return the data in JSON format:
      {
        "artists": [
          {
            "name": "The Basement Dwellers",
            "genre": "Garage Rock",
            "energy": 70,
            "talent": 25,
            "required_level": 1,
            "traits": {
              "charisma": 30,
              "creativity": 40,
              "resilience": 20,
              "discipline": 15
            },
            "background": "Three friends who started playing in their parents' garage after failing shop class."
          },
          // More artists...
        ]
      }
    PROMPT
  end

  # New method to fetch specifically affordable artists from GPT
  def fetch_affordable_artists(count)
    return [] if Rails.env.test?

    Rails.logger.info("Requesting #{count} affordable artists from OpenAI API")

    response = @client.chat(
      parameters: {
        model: "gpt-4o-mini",
        messages: [
          { role: "system", content: system_prompt },
          { role: "user", content: affordable_artist_prompt(count) }
        ],
        temperature: 1.0,
        response_format: { type: "json_object" }
      }
    )

    # Parse the response
    raw_content = response.dig("choices", 0, "message", "content")

    begin
      parsed_data = JSON.parse(raw_content)
      artists = extract_artist_array(parsed_data)

      # Verify affordability of returned artists
      affordable_artists = artists.select { |artist| is_affordable_for_new_player?(artist) }

      if affordable_artists.size < artists.size
        Rails.logger.warn("GPT returned some non-affordable artists (#{affordable_artists.size}/#{artists.size})")
      end

      affordable_artists
    rescue JSON::ParserError => e
      Rails.logger.error("Failed to parse JSON response for affordable artists: #{e.message}")
      []
    end
  end

  # Prompt specifically for affordable artists
  def affordable_artist_prompt(count)
    <<~PROMPT
      Generate EXACTLY #{count} AFFORDABLE artist profiles for new players in our music management game.

      CRITICAL REQUIREMENTS:
      - These MUST be affordable for new players with only $1,000 to spend
      - All artists MUST cost UNDER $1,000 to sign
      - ALL artists MUST be level 1
      - Talent must be in the 5-30 range (mostly 5-20)
      - No more than one trait should be above 40
      - Average trait value should be under 35

      TALENT DISTRIBUTION:
      - 80% should have very low talent (5-20 range)
      - 20% can have low talent (21-30 range)

      IMPORTANT: Make these artists interesting and diverse despite their low talent!
      - Varied genres (folk, indie, punk, electronic, hip-hop, etc.)
      - Creative band and artist names
      - Unique backstories appropriate to beginners, slighly quirky and funny
      - Different trait combinations (one might be creative but not disciplined, etc.)

      Return the data in this JSON format:
      {
        "artists": [
          {
            "name": "The Basement Tapes",
            "genre": "Lo-Fi Indie Folk",
            "energy": 55,
            "talent": 15,
            "required_level": 1,
            "traits": {
              "charisma": 25,
              "creativity": 38,
              "resilience": 20,
              "discipline": 15
            },
            "background": "College roommates who started recording on an old cassette deck in their dorm."
          },
          // More affordable artists...
        ]
      }
    PROMPT
  end

  # Helper method to adjust a batch for better affordability
  def adjust_batch_for_affordability(batch)
    return batch if batch.empty?

    # Count how many are already affordable
    current_affordable = batch.count { |artist| is_affordable_for_new_player?(artist) }
    affordable_percentage = ((current_affordable.to_f / batch.size) * 100).round

    # Target size for the final batch
    target_size = batch.size

    # If we already have enough affordable artists, return the batch
    if affordable_percentage >= 50
      return batch
    end

    # Calculate how many affordable artists we need to add
    needed_affordable = (target_size * 0.5).ceil - current_affordable
    needed_affordable = [ needed_affordable, 1 ].max # At least 1

    # Try to get affordable artists from the API
    affordable_artists = fetch_affordable_artists(needed_affordable)

    # If we couldn't get any affordable artists, adjust existing ones
    if affordable_artists.empty?
      # Modify some non-affordable artists to make them affordable
      non_affordable = batch.reject { |artist| is_affordable_for_new_player?(artist) }

      non_affordable.sample(needed_affordable).each do |artist|
        # Lower talent to make more affordable
        artist["talent"] = [ artist["talent"].to_i, 30 ].min

        # Ensure level 1
        artist["required_level"] = 1

        # Explicitly set signing cost
        artist["signing_cost"] = rand(500..950)
      end
    else
      # Replace some non-affordable artists with affordable ones
      non_affordable_indices = batch.each_with_index
                                    .reject { |artist, _| is_affordable_for_new_player?(artist) }
                                    .map { |_, index| index }
                                    .sample([ affordable_artists.size, needed_affordable ].min)

      non_affordable_indices.each_with_index do |batch_index, affordable_index|
        if affordable_index < affordable_artists.size
          batch[batch_index] = affordable_artists[affordable_index]
        end
      end
    end

    # Check the final affordability
    final_batch = batch
    new_affordable_count = final_batch.count { |artist| is_affordable_for_new_player?(artist) }
    new_affordable_percentage = ((new_affordable_count.to_f / target_size) * 100).round

    Rails.logger.info("Adjustment complete: Affordable artists: #{current_affordable} → #{new_affordable_count} (#{affordable_percentage}% → #{new_affordable_percentage}%)")

    final_batch
  end

  # Analyze batch for affordability metrics
  def analyze_batch_affordability(artist_data_batch)
    total_count = artist_data_batch.size
    return { affordable_count: 0, affordable_percentage: 0 } if total_count == 0

    # Count artists by talent range with our new thresholds
    very_low_talent = artist_data_batch.count { |a| a["talent"].to_i <= 20 }
    low_talent = artist_data_batch.count { |a| a["talent"].to_i > 20 && a["talent"].to_i <= 30 }
    mid_talent = artist_data_batch.count { |a| a["talent"].to_i > 30 && a["talent"].to_i <= 60 }
    high_talent = artist_data_batch.count { |a| a["talent"].to_i > 60 }

    # Count affordable artists using same logic as is_affordable_for_new_player?
    affordable_count = artist_data_batch.count { |artist| is_affordable_for_new_player?(artist) }
    affordable_percentage = ((affordable_count.to_f / total_count) * 100).round

    # Count level distribution
    level_1_count = artist_data_batch.count { |a| a["required_level"].to_i == 1 }
    level_1_percentage = ((level_1_count.to_f / total_count) * 100).round

    # Return comprehensive stats about the batch
    {
      total_count: total_count,
      very_low_talent_count: very_low_talent,
      very_low_talent_percentage: ((very_low_talent.to_f / total_count) * 100).round,
      low_talent_count: low_talent,
      low_talent_percentage: ((low_talent.to_f / total_count) * 100).round,
      mid_talent_count: mid_talent,
      mid_talent_percentage: ((mid_talent.to_f / total_count) * 100).round,
      high_talent_count: high_talent,
      high_talent_percentage: ((high_talent.to_f / total_count) * 100).round,
      affordable_count: affordable_count,
      affordable_percentage: affordable_percentage,
      level_1_count: level_1_count,
      level_1_percentage: level_1_percentage
    }
  end
end

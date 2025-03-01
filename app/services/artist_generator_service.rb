class ArtistGeneratorService
  class GenerationError < StandardError; end
  class InvalidArtistDataError < StandardError; end

  require "securerandom"

  REQUIRED_FIELDS = %w[name genre energy talent].freeze

  def self.generate(user = nil)
    # Refactored to use batch generation with count = 1
    new(user).generate_artist_batch(1).first
  end

  def self.generate_batch(count = 10, user = nil)
    new(user).generate_artist_batch(count)
  end

  def initialize(user = nil)
    @user = user
    @client = OpenAI::Client.new unless Rails.env.test?
  end

  def generate_artist_batch(count)
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

  def fetch_artist_batch_data(count)
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

    # Set current energy
    current_energy = data["energy"].present? ?
                    data["energy"].to_i :
                    rand((max_energy * min_energy_percent).to_i..max_energy)
    current_energy = [ current_energy, max_energy ].min

    # Create and return the artist
    Artist.create!(
      name: data["name"],
      genre: data["genre"],
      energy: current_energy,
      max_energy: max_energy,
      talent: data["talent"],
      skill: base_skill,
      traits: traits,
      background: data["background"],
      required_level: required_level
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

      GENRE DIVERSITY:
      - Include a wide range of music genres
      - Make sure to include both mainstream and niche genres
      - Genre should influence the artist name style (e.g., metal bands vs. pop artists)

      BACKGROUND STORIES:
      - Keep backgrounds short but specific to the artist's genre and talent level
      - Low talent artists should have more modest or beginning-stage backgrounds
      - Higher talent artists can have more accomplished backgrounds

      NAMING GUIDELINES:
      - Names should be realistic, memorable, and genre-appropriate
      - For level 1 artists, sometimes include hints that they're new ("The Rookies", etc.)
      - Never use known real band names

      ENSURE DIVERSITY:
      - Create a mix of solo artists and bands
      - Vary the energy levels appropriately
      - Include diversity in backgrounds and artistic journeys

      Remember that this is for a game about managing music artists, so balance and strategy are important. The data should be formatted as a valid JSON array of objects.
    PROMPT
  end

  # Method to extract and validate traits from artist data
  def extract_traits(data)
    # Ensure traits is a hash
    traits = data["traits"] || {}

    # If traits is a string, try to parse it as JSON
    if traits.is_a?(String)
      begin
        parsed_traits = JSON.parse(traits)
        traits = parsed_traits if parsed_traits.is_a?(Hash)
      rescue JSON::ParserError
        traits = {}
      end
    end

    # Ensure all trait values are numeric
    if traits.is_a?(Hash)
      traits.each do |key, value|
        if value.is_a?(String) && value.match?(/^\d+(\.\d+)?$/)
          # Keep as float for trait values since they don't have integer validation
          traits[key] = value.to_f
        end
      end
    else
      # If traits is not a hash, set it to an empty hash
      traits = {}
    end

    traits
  end

  # Replace the individual user_prompt with a batch_user_prompt that handles count=1
  def batch_user_prompt(count)
    # Different prompt formatting based on whether we're generating one artist or multiple
    if count == 1
      <<~PROMPT
        Generate a single artist profile with the following requirements:

        - The artist should be appropriate for a music management game
        - Please include: name, genre, energy, talent, traits, background, and required_level
        - Energy must be between 40-100
        - Talent must be between 1-100
        - Required_level must be between 1-5

        CRITICALLY IMPORTANT - AFFORDABILITY:
        - New players only have $1,000 to spend on signing artists
        - There should be a 70% chance this artist costs UNDER $1,000
        - To achieve this, there should be a 70% chance this artist has talent under 30
        - Artists with talent under 20 should ALWAYS be level 1
        - Artists with talent between 20-30 should be level 1 with modest trait values

        Return the data as a valid JSON object.
      PROMPT
    else
      <<~PROMPT
        Generate #{count} artist profiles as a JSON array.

        REQUIRED LEVEL DISTRIBUTION:
        - Level 1: 80% of artists (approximately #{(count * 0.8).to_i} artists)
        - Level 2: 15% of artists (approximately #{(count * 0.15).to_i} artists)
        - Level 3: 4% of artists (approximately #{(count * 0.04).to_i} artists)
        - Level 4-5: 1% of artists (approximately #{(count * 0.01).to_i} artists)

        CRITICAL AFFORDABILITY REQUIREMENT:#{' '}
        New players only have $1,000 to spend, so AT LEAST 60% of generated artists#{' '}
        MUST be affordable at that price point (costing under $1,000).

        TALENT DISTRIBUTION REQUIREMENTS:
        - At least 60% MUST have LOW talent (1-30 range, with many in the 5-20 range)
        - Around 25% should have MODERATE talent (31-60 range)
        - Only 15% should have HIGH talent (61-100 range)

        AFFORDABILITY RULES:
        - ALL artists with talent below 20 MUST be level 1 with modest traits
        - ALL artists with talent 20-30 should be level 1 with at most one trait above 40
        - NO artist with talent below 30 should cost more than $1,000
        - LOW talent artists should have trait values in the 5-40 range
        - MODERATE talent artists should have trait values in the 20-60 range
        - HIGH talent artists can have trait values in the 30-80 range

        Return the data in this format:#{' '}
        {
          "artists": [
            {
              "name": "The Garage Echoes",
              "genre": "Indie Rock",
              "energy": 65,
              "talent": 15,  // Example of a low-talent affordable artist
              "required_level": 1,
              "traits": {
                "charisma": 20,
                "creativity": 25,
                "resilience": 30,
                "discipline": 15
              },
              "background": "Started playing music in their parents' garage after dropping out of community college."
            },
            // More artists following the distribution requirements
          ]
        }
      PROMPT
    end
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

  # Check if an artist is affordable for a new player (with $1,000)
  def is_affordable_for_new_player?(artist)
    # Fast path for clearly affordable artists
    talent = artist["talent"].to_i
    level = artist["required_level"].to_i

    # Level 1 artists with very low talent are always affordable
    return true if level == 1 && talent <= 20

    # Level 1 artists with low talent and balanced traits are likely affordable
    if level == 1 && talent <= 30 && has_low_traits?(artist)
      return true
    end

    # For all other artists, use the full cost estimation
    estimated_cost = estimate_artist_cost(artist)
    estimated_cost <= 1000
  end

  # Estimate the signing cost of an artist
  def estimate_artist_cost(artist)
    # Base on formula from the database data that shows the actual costs
    talent = artist["talent"].to_i
    required_level = artist["required_level"].to_i

    if required_level == 1
      # Level 1 artists: much more affordable
      if talent <= 20
        # Very low talent: $800-1250 range
        base_cost = 800 + (talent * 25)
      elsif talent <= 30
        # Low talent: $1250-2000 range
        base_cost = 1000 + (talent * 35)
      elsif talent <= 45
        # Lower-mid talent: $2000-3500 range
        base_cost = 1500 + (talent * 45)
      elsif talent <= 65
        # Mid talent: $3500-6500 range
        base_cost = 2000 + (talent * 70)
      else
        # High talent: $6500+ range
        base_cost = 3000 + (talent * 80)
      end
    else
      # Higher level artists are much more expensive
      level_multiplier = case required_level
      when 2 then 1.8
      when 3 then 3.0
      when 4 then 5.0
      when 5 then 8.0
      else 1.0
      end

      base_cost = (2000 + (talent * 80)) * level_multiplier
    end

    # Adjust for high trait values (but less impact than before)
    if artist["traits"].is_a?(Hash)
      trait_sum = 0
      trait_count = 0

      %w[charisma creativity discipline resilience].each do |trait|
        if artist["traits"][trait].present?
          trait_value = artist["traits"][trait].to_i
          if trait_value > 70
            trait_sum += trait_value
            trait_count += 1
          end
        end
      end

      if trait_count > 0
        average_high_trait = trait_sum / trait_count
        trait_multiplier = 1.0 + ((average_high_trait - 70) * 0.003)
        base_cost = (base_cost * trait_multiplier).to_i
      end
    end

    base_cost.to_i
  end

  # Check if an artist has generally low trait values
  def has_low_traits?(artist)
    return false unless artist["traits"].is_a?(Hash)

    # Count how many high traits the artist has
    high_trait_count = 0
    total_trait_value = 0

    %w[charisma creativity discipline resilience].each do |trait|
      if artist["traits"][trait].present?
        trait_value = artist["traits"][trait].to_i
        total_trait_value += trait_value
        high_trait_count += 1 if trait_value > 40
      end
    end

    # Artist has balanced traits if no more than one trait is high
    # and the average trait value is reasonable
    high_trait_count <= 1 && (total_trait_value / 4.0) <= 35
  end

  # Adjust a batch to ensure enough affordable artists
  def adjust_batch_for_affordability(artist_data_batch)
    target_size = artist_data_batch.size
    affordable_target = (target_size * 0.5).ceil # At least 50% should be affordable
    max_attempts = 3 # Safety limit on number of GPT calls

    # First identify artists that are already affordable
    affordable_artists = artist_data_batch.select do |artist|
      is_affordable_for_new_player?(artist)
    end

    current_affordable = affordable_artists.size
    affordable_percentage = ((current_affordable.to_f / target_size) * 100).round
    needed_affordable = affordable_target - current_affordable

    # If we already have enough affordable artists, return the original batch
    return artist_data_batch if needed_affordable <= 0

    # Initialize collection for all new affordable artists
    all_new_affordable_artists = []
    remaining_needed = needed_affordable
    attempts = 0

    # Make multiple attempts if needed, but limit to max_attempts
    while remaining_needed > 0 && attempts < max_attempts
      attempts += 1
      Rails.logger.info("Attempt #{attempts}/#{max_attempts}: Requesting #{remaining_needed} affordable artists from GPT")

      # Request specifically affordable artists from GPT
      new_batch = fetch_affordable_artists(remaining_needed)

      # If we got some artists, add them to our collection
      if new_batch.any?
        all_new_affordable_artists.concat(new_batch)
        remaining_needed = needed_affordable - all_new_affordable_artists.size

        Rails.logger.info("Got #{new_batch.size} affordable artists, still need #{remaining_needed} more")
      else
        Rails.logger.warn("Received no affordable artists in this batch")
      end

      # Break if we have enough or if we got nothing in this attempt
      break if remaining_needed <= 0 || new_batch.empty?
    end

    # Log if we reached the max attempts limit
    if attempts >= max_attempts && remaining_needed > 0
      Rails.logger.warn("Reached maximum GPT call attempts (#{max_attempts}). Proceeding with #{all_new_affordable_artists.size}/#{needed_affordable} affordable artists")
    end

    # If we didn't get any affordable artists, return the original batch
    return artist_data_batch if all_new_affordable_artists.empty?

    # Replace the highest talent/most expensive artists first to preserve diversity
    high_value_artists = artist_data_batch.select { |a| a["talent"].to_i > 60 }
    sorted_high_value = high_value_artists.sort_by { |a| -a["talent"].to_i }

    # If we don't have enough high-value artists, also replace some mid-value ones
    if sorted_high_value.size < all_new_affordable_artists.size
      mid_value_artists = artist_data_batch.select { |a| a["talent"].to_i > 40 && a["talent"].to_i <= 60 }
      sorted_mid_value = mid_value_artists.sort_by { |a| -a["talent"].to_i }

      replaceable_artists = sorted_high_value + sorted_mid_value
      replaceable_artists = replaceable_artists.take(all_new_affordable_artists.size)
    else
      replaceable_artists = sorted_high_value.take(all_new_affordable_artists.size)
    end

    # Create the final adjusted batch
    final_batch = artist_data_batch.dup

    replaceable_artists.each_with_index do |artist, index|
      break if index >= all_new_affordable_artists.size

      # Find this artist in the final batch and replace it
      artist_index = final_batch.find_index { |a| a == artist }
      if artist_index
        final_batch[artist_index] = all_new_affordable_artists[index]
      end
    end

    # Log the results of the adjustment
    new_affordable_count = final_batch.count { |artist| is_affordable_for_new_player?(artist) }
    new_affordable_percentage = ((new_affordable_count.to_f / target_size) * 100).round

    Rails.logger.info("Adjustment complete: Affordable artists: #{current_affordable} → #{new_affordable_count} (#{affordable_percentage}% → #{new_affordable_percentage}%)")

    final_batch
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

      Return the data in this format:
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
end

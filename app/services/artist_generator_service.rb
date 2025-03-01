class ArtistGeneratorService
  class GenerationError < StandardError; end
  class InvalidArtistDataError < StandardError; end

  REQUIRED_FIELDS = %w[name genre energy talent].freeze

  def self.generate(user = nil)
    new(user).generate_artist
  end

  def self.generate_batch(count = 10, user = nil)
    new(user).generate_artist_batch(count)
  end

  def initialize(user = nil)
    @user = user
    unless Rails.env.test?
      @client = OpenAI::Client.new
    end
  end

  def generate_artist
    begin
      Rails.logger.info("Starting artist generation process")
      artist_data = fetch_artist_data
      Rails.logger.info("Artist data fetched successfully: #{artist_data.slice("name", "genre").inspect}")

      validate_artist_data(artist_data)
      Rails.logger.info("Artist data validated successfully")

      artist = create_artist(artist_data)
      Rails.logger.info("Artist object type: #{artist.class}")
      Rails.logger.info("Artist created successfully: #{artist.is_a?(Artist) ? artist.name : 'Unknown'}")

      artist
    rescue InvalidArtistDataError => e
      Rails.logger.error("Invalid artist data: #{e.message}")
      Rails.logger.error("Artist data: #{artist_data.inspect}") if defined?(artist_data)
      # Let InvalidArtistDataError bubble up
      raise
    rescue StandardError => e
      Rails.logger.error("Error generating artist: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))
      raise GenerationError, "Failed to generate artist: #{e.message}"
    end
  end

  def generate_artist_batch(count)
    begin
      Rails.logger.info("Starting batch generation of #{count} artists")
      artist_data_batch = fetch_artist_batch_data(count)
      Rails.logger.info("Artist batch data fetched successfully, processing...")

      # Extract artists array if the data is in the format ["artists", [array_of_artist_objects]]
      if artist_data_batch.is_a?(Array) && artist_data_batch.length == 2 &&
         artist_data_batch[0].is_a?(String) && artist_data_batch[1].is_a?(Array)
        # The data is in the format ["key", [array_of_objects]]
        Rails.logger.info("Data in format [\"key\", [array_of_objects]], extracting array")
        artist_data_batch = artist_data_batch[1]
      end

      # Handle case where data might be wrapped in a hash with an 'artists' key
      if artist_data_batch.is_a?(Hash) && artist_data_batch["artists"].is_a?(Array)
        Rails.logger.info("Data wrapped in hash with 'artists' key, extracting array")
        artist_data_batch = artist_data_batch["artists"]
      end

      # Ensure we have an array of artist data hashes
      unless artist_data_batch.is_a?(Array)
        error_msg = "Expected array of artist data, got: #{artist_data_batch.class}"
        Rails.logger.error(error_msg)
        Rails.logger.error("Data: #{artist_data_batch.inspect}")
        raise InvalidArtistDataError, error_msg
      end

      Rails.logger.info("Processing #{artist_data_batch.length} artists")
      artists = []

      artist_data_batch.each_with_index do |artist_data, index|
        begin
          Rails.logger.info("Validating artist #{index + 1}/#{artist_data_batch.length}: #{artist_data["name"]}")
          validate_artist_data(artist_data)

          Rails.logger.info("Creating artist #{index + 1}/#{artist_data_batch.length}: #{artist_data["name"]}")
          artist = create_artist(artist_data)

          Rails.logger.info("Artist created successfully: #{artist.name}")
          artists << artist
        rescue => e
          Rails.logger.error("Error creating artist #{index + 1}/#{artist_data_batch.length}: #{e.message}")
          Rails.logger.error("Artist data: #{artist_data.inspect}")
          # Continue with the next artist instead of failing the entire batch
        end
      end

      Rails.logger.info("Batch generation completed. Successfully created #{artists.length}/#{artist_data_batch.length} artists")
      artists
    rescue InvalidArtistDataError => e
      # Let InvalidArtistDataError bubble up
      Rails.logger.error("Invalid artist data batch: #{e.message}")
      raise
    rescue StandardError => e
      Rails.logger.error("Error generating artist batch: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))
      raise GenerationError, "Failed to generate artist batch: #{e.message}"
    end
  end

  private

  def fetch_artist_data
    if Rails.env.test?
      Rails.logger.info("Test mode: Using mock artist data")
      {}  # In test mode, this will be stubbed
    else
      # Actual implementation with OpenAI API
      Rails.logger.info("Fetching artist data from OpenAI API")
      response = @client.chat(
        parameters: {
          model: "gpt-4o-mini",
          messages: [
            { role: "system", content: system_prompt },
            { role: "user", content: user_prompt }
          ],
          temperature: 1.0,
          response_format: { type: "json_object" }
        }
      )

      # Extract the JSON from the response
      raw_content = response.dig("choices", 0, "message", "content")
      Rails.logger.info("Received raw API response")

      begin
        parsed_data = JSON.parse(raw_content)
        Rails.logger.info("Successfully parsed JSON response")
        parsed_data
      rescue JSON::ParserError => e
        Rails.logger.error("Failed to parse JSON from API response: #{e.message}")
        Rails.logger.error("Raw content: #{raw_content}")
        raise InvalidArtistDataError, "Invalid data format returned from API"
      end
    end
  end

  def fetch_artist_batch_data(count)
    if Rails.env.test?
      Rails.logger.info("Test mode: Using mock artist batch data")
      []  # In test mode, this will be stubbed
    else
      # Actual implementation with OpenAI API
      Rails.logger.info("Fetching batch of #{count} artists from OpenAI API")
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

      # Extract the JSON from the response
      raw_content = response.dig("choices", 0, "message", "content")
      Rails.logger.info("Received raw API response for batch")

      begin
        parsed_data = JSON.parse(raw_content)
        Rails.logger.info("Successfully parsed JSON batch response")

        # Handle various response formats
        if parsed_data.is_a?(Hash)
          # Look for an array in common keys
          if parsed_data["artists"].is_a?(Array)
            Rails.logger.info("Found artists array in response")
            return parsed_data["artists"]
          elsif parsed_data["profiles"].is_a?(Array)
            Rails.logger.info("Found profiles array in response")
            return parsed_data["profiles"]
          elsif parsed_data["data"].is_a?(Array)
            Rails.logger.info("Found data array in response")
            return parsed_data["data"]
          else
            # If we can't find an array by key, check all hash values
            parsed_data.each_value do |value|
              if value.is_a?(Array) && value.all? { |item| item.is_a?(Hash) }
                Rails.logger.info("Found array in hash value")
                return value
              end
            end

            # If no array found and this looks like a single artist, wrap it
            if REQUIRED_FIELDS.all? { |field| parsed_data.key?(field) }
              Rails.logger.info("Response contains a single artist, wrapping in array")
              return [ parsed_data ]
            end
          end
        elsif parsed_data.is_a?(Array)
          # If it's already an array, return it directly if elements look like artist data
          if parsed_data.all? { |item| item.is_a?(Hash) }
            Rails.logger.info("Response is already an array of artists")
            return parsed_data
          end

          # Special case for ["artists", [array_of_artist_objects]] format
          if parsed_data.length == 2 && parsed_data[0].is_a?(String) && parsed_data[1].is_a?(Array)
            Rails.logger.info("Response in special format [\"key\", [array]]")
            return parsed_data[1]
          end
        end

        # If we get here, the format wasn't recognized
        Rails.logger.error("Unrecognized response format: #{parsed_data.inspect}")
        raise InvalidArtistDataError, "Invalid data format returned from API"

      rescue JSON::ParserError => e
        Rails.logger.error("Failed to parse JSON from API response: #{e.message}")
        Rails.logger.error("Raw content: #{raw_content}")
        raise InvalidArtistDataError, "Invalid data format returned from API"
      end
    end
  end

  def parse_response(response)
    return {} if Rails.env.test?

    content = response.dig("choices", 0, "message", "content")
    raise GenerationError, "Invalid API response format" unless content

    JSON.parse(content)
  rescue JSON::ParserError
    raise GenerationError, "Failed to parse API response as JSON"
  end

  def parse_batch_response(response)
    return [] if Rails.env.test?

    content = response.dig("choices", 0, "message", "content")
    raise GenerationError, "Invalid API response format" unless content

    parsed_content = JSON.parse(content)

    # Handle different potential response structures
    if parsed_content.is_a?(Hash)
      # Look for array of artists in common keys
      if parsed_content["artists"].is_a?(Array)
        return parsed_content["artists"]
      elsif parsed_content["profiles"].is_a?(Array)
        return parsed_content["profiles"]
      elsif parsed_content["data"].is_a?(Array)
        return parsed_content["data"]
      else
        # If there's only one artist in the response
        if REQUIRED_FIELDS.all? { |field| parsed_content.key?(field) }
          return [ parsed_content ]
        end

        # If we can't find an array, check all hash values for arrays
        parsed_content.each_value do |value|
          return value if value.is_a?(Array) && value.all? { |item| item.is_a?(Hash) }
        end
      end

      # If we couldn't find an array, return an empty array
      Rails.logger.error("Could not find array of artists in response: #{parsed_content.inspect}")
      []
    elsif parsed_content.is_a?(Array)
      # The API returned an array directly
      parsed_content
    else
      # Unexpected format
      Rails.logger.error("Unexpected response format: #{parsed_content.inspect}")
      []
    end
  rescue JSON::ParserError
    raise GenerationError, "Failed to parse API response as JSON"
  end

  def validate_artist_data(data)
    # Ensure data is a hash
    unless data.is_a?(Hash)
      error_msg = "Artist data must be a hash, got #{data.class}: #{data.inspect}"
      Rails.logger.error(error_msg)
      raise InvalidArtistDataError, error_msg
    end

    # Check for missing required fields
    missing_fields = REQUIRED_FIELDS.select { |field| !data.key?(field) || data[field].nil? }
    unless missing_fields.empty?
      error_msg = "Missing required fields: #{missing_fields.join(', ')}"
      Rails.logger.error(error_msg)
      Rails.logger.error("Artist data: #{data.inspect}")
      raise InvalidArtistDataError, error_msg
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
        error_msg = "#{field} must be a number between 0 and 100, got: #{value.inspect}"
        Rails.logger.error(error_msg)
        raise InvalidArtistDataError, error_msg
      end
    end

    # Validate genre is a non-empty string
    if data["genre"].nil? || data["genre"].to_s.strip.empty?
      error_msg = "genre must be a non-empty string"
      Rails.logger.error(error_msg)
      raise InvalidArtistDataError, error_msg
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
        error_msg = "required_level must be a number between 1 and 5, got: #{value.inspect}"
        Rails.logger.error(error_msg)
        raise InvalidArtistDataError, error_msg
      end
    end

    Rails.logger.info("Artist data validated: #{data["name"]} (#{data["genre"]}) - Energy: #{data["energy"]}, Talent: #{data["talent"]}")
  end

  def create_artist(data)
    begin
      Rails.logger.info("Starting to create artist: #{data["name"]}")
      data = data.with_indifferent_access

      # Ensure numeric fields are actually numeric
      %w[energy talent].each do |field|
        data[field] = data[field].to_i if data[field].present?
      end

      # Ensure genre is stored as a string
      if data["genre"].present?
        # Always ensure genre is a string
        data["genre"] = data["genre"].to_s
      end

      # Validate and extract traits
      begin
        traits = extract_traits(data)
        Rails.logger.info("Extracted traits: #{traits.inspect}")
      rescue => e
        Rails.logger.error("Error extracting traits: #{e.message}")
        traits = {}
      end

      # Calculate required level based on talent
      begin
        talent_value = data["talent"].to_i
        required_level = if Rails.env.test?
                          1  # Simplified for tests
        else
                          # Base probability weighted toward level 1
                          level_weights = [ 70, 20, 7, 2, 1 ]  # Percentages for levels 1-5

                          # Adjust weights based on talent
                          if talent_value > 80  # Very talented artists
                            level_weights = [ 40, 30, 20, 7, 3 ]
                          elsif talent_value > 60  # Fairly talented artists
                            level_weights = [ 50, 30, 15, 4, 1 ]
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
        Rails.logger.info("Calculated required level: #{required_level}")
      end

      # Calculate initial skill based on talent and other factors
      # New formula incorporating multiple attributes for more dynamic skill calculation
      begin
        resilience_value = traits["resilience"].to_i
        discipline_value = traits["discipline"].to_i
        creativity_value = traits["creativity"].to_i

        # Enhanced skill calculation that's more heavily influenced by talent
        # Base skill now incorporates talent (50%), discipline (20%), creativity (20%), and a small random component (10%)
        base_skill = (talent_value * 0.5).to_i +
                    (discipline_value * 0.2).to_i +
                    (creativity_value * 0.2).to_i +
                    rand(1..[ (talent_value * 0.1).to_i, 1 ].max)

        # Add a bonus for exceptional talent (over 85)
        if talent_value > 85
          base_skill += (talent_value - 85) / 2
        end

        # Cap skill at a reasonable starting value based on talent tier
        max_starting_skill = case
        when talent_value > 80 then 80
        when talent_value > 60 then 70
        when talent_value > 40 then 60
        else 50
        end

        base_skill = [ base_skill, max_starting_skill ].min
        Rails.logger.info("Calculated initial skill: #{base_skill}")
      rescue => e
        Rails.logger.error("Error calculating skill: #{e.message}")
        base_skill = talent_value / 2 # Fallback calculation
      end

      # Calculate max energy based on resilience
      begin
        # Formula: Max Energy = 100 + (Resilience × 0.5) + (Level × 5)
        # For new artists, we'll use required_level as their level
        max_energy = 100 + (resilience_value * 0.5).to_i + (required_level * 5)

        # Make energy more variable - each artist starts with a different percentage of their max energy
        # Low resilience artists will tend to start with less energy
        min_energy_percent = if resilience_value < 30
                               0.6 # 60% minimum for low resilience
        elsif resilience_value < 60
                               0.7 # 70% minimum for medium resilience
        else
                               0.8 # 80% minimum for high resilience
        end

        # The current energy value from data (or default to a variable percentage of max if not specified)
        current_energy = data["energy"].present? ?
                        data["energy"].to_i :
                        rand((max_energy * min_energy_percent).to_i..max_energy)

        # Ensure energy doesn't exceed maximum
        current_energy = [ current_energy, max_energy ].min
        Rails.logger.info("Calculated energy values - Max: #{max_energy}, Current: #{current_energy}")
      rescue => e
        Rails.logger.error("Error calculating energy: #{e.message}")
        max_energy = 100
        current_energy = data["energy"].present? ? data["energy"].to_i : 70
      end

      # Create the artist record with all calculated attributes
      begin
        Rails.logger.info("Creating Artist record in database")
        artist = Artist.create!(
          name: data["name"],
          genre: data["genre"],
          energy: current_energy,
          max_energy: max_energy,
          talent: data["talent"],
          skill: base_skill, # Set the base skill from our calculation
          traits: traits,
          background: data["background"],
          required_level: required_level,
          user: @user
        )

        # Log without trying to access artist.genre directly which might cause issues
        Rails.logger.info("Artist successfully created with ID: #{artist.id}, Name: #{artist.name}")
        artist
      rescue => e
        Rails.logger.error("Error in create_artist artist creation: #{e.message}")
        Rails.logger.error(e.backtrace.join("\n"))
        raise
      end
    rescue => e
      Rails.logger.error("Error in create_artist: #{e.message}")
      Rails.logger.error("Artist data that failed: #{data.inspect}")
      Rails.logger.error(e.backtrace.join("\n"))
      raise
    end
  end

  def system_prompt
    <<~PROMPT
      You are a music industry expert who creates realistic artist profiles for a music management game.

      Generate realistic and diverse artist profiles with the following attributes:
      - name: A creative and realistic band or artist name
      - genre: A specific music genre (e.g., "Indie Rock", "Synthwave", "Hip Hop")
      - energy: A number from 0-100 representing the artist's current energy level
      - talent: A number from 0-100 representing the artist's natural talent
      - traits: An object containing personality traits that affect the artist's career:
        - charisma: A number from 0-100 representing stage presence and fan interaction
        - creativity: A number from 0-100 representing songwriting and artistic innovation
        - resilience: A number from 0-100 representing ability to handle setbacks
        - discipline: A number from 0-100 representing work ethic and reliability
      - background: A brief backstory for the artist (1-2 sentences), be a little creative/quirky
      - required_level: A number from 1-5 representing the manager level needed to sign this artist (higher level = rarer/more valuable artist)

      IMPORTANT: Ensure a WIDE DISTRIBUTION of artist traits and attributes:
      - Create a mix of high and low talent artists (0-20, 21-40, 41-60, 61-80, 81-100)
      - Vary trait combinations significantly (don't make all traits consistently high or low)
      - Include some specialized artists (very high in 1-2 traits, lower in others)
      - Include some balanced artists (moderate values across all traits)
      - Include rare "unicorn" artists with multiple high traits (but make these uncommon)
      - Vary energy levels significantly (30-100), with less energetic artists being more common

      For required_level distribution:
      - Level 1: ~70% of artists (beginners, most accessible)
      - Level 2: ~20% of artists (showing promise)
      - Level 3: ~7% of artists (established talent)
      - Level 4: ~2% of artists (exceptional artists)
      - Level 5: ~1% of artists (superstar potential)

      This diversity is critical for gameplay as it affects costs and player strategies.
      The signing cost for artists is calculated based on talent and level requirements,
      so ensure a good mix of both high-value and budget-friendly artists.

      Provide the response as a valid JSON object.

      Example response:
      {
        "name": "The Velveteers",
        "genre": "Indie Rock",
        "energy": 85,
        "talent": 90,
        "traits": {
          "charisma": 80,
          "creativity": 75,
          "resilience": 95,
          "discipline": 88
        },
        "background": "The Velveteers are a band from Los Angeles that formed in 2015.",
        "required_level": 3
      }
    PROMPT
  end

  # Method to extract and validate traits from artist data
  def extract_traits(data)
    Rails.logger.info("Extracting traits from artist data")
    # Ensure traits is a hash
    traits = data["traits"] || {}

    # If traits is a string, try to parse it as JSON
    if traits.is_a?(String)
      begin
        parsed_traits = JSON.parse(traits)
        traits = parsed_traits if parsed_traits.is_a?(Hash)
        Rails.logger.info("Parsed traits from JSON string")
      rescue JSON::ParserError
        Rails.logger.warn("Could not parse traits as JSON: #{traits}")
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
      Rails.logger.warn("Traits is not a hash, defaulting to empty hash")
      traits = {}
    end

    Rails.logger.info("Extracted traits: #{traits.inspect}")
    traits
  end

  def user_prompt
    "Generate a single artist profile"
  end

  def batch_user_prompt(count)
    <<~PROMPT
      Generate #{count} artist profiles as a JSON array.

      Return the data in this format:#{' '}
      {
        "artists": [
          {
            "name": "Artist Name",
            "genre": "Genre",
            "energy": 70,
            "talent": 80,
            ...other attributes
          },
          ...more artists
        ]
      }

      Each artist must have at minimum: name, genre, energy, and talent.
      Energy and talent must be integers between 0 and 100.
    PROMPT
  end
end

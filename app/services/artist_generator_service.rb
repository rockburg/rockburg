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
      artist_data = fetch_artist_data
      validate_artist_data(artist_data)
      create_artist(artist_data)
    rescue InvalidArtistDataError => e
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
      artist_data_batch = fetch_artist_batch_data(count)
      artists = []

      artist_data_batch.each do |artist_data|
        validate_artist_data(artist_data)
        artists << create_artist(artist_data)
      end

      artists
    rescue InvalidArtistDataError => e
      # Let InvalidArtistDataError bubble up
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
      # In test environment, we don't make actual API calls
      # The test will stub this method to return mock data
      {}
    else
      response = @client.chat(
        parameters: {
          model: "gpt-4o-mini",
          messages: [
            { role: "system", content: system_prompt },
            { role: "user", content: "Generate a single artist profile" }
          ],
          temperature: 0.5
        }
      )

      parse_response(response)
    end
  end

  def fetch_artist_batch_data(count)
    if Rails.env.test?
      # In test environment, we don't make actual API calls
      # The test will stub this method to return mock data
      []
    else
      response = @client.chat(
        parameters: {
          model: "gpt-4o-mini",
          messages: [
            { role: "system", content: system_prompt },
            { role: "user", content: "Generate #{count} artist profiles" }
          ],
          temperature: 0.9,
          response_format: { type: "json_object" }
        }
      )

      parse_batch_response(response)
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
      raise InvalidArtistDataError, "Artist data must be a hash, got #{data.class}: #{data.inspect}"
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
  end

  def create_artist(data)
    # Ensure traits is a hash
    traits = data["traits"] || {}

    # If traits is a string, try to parse it as JSON
    if traits.is_a?(String)
      begin
        parsed_traits = JSON.parse(traits)
        traits = parsed_traits if parsed_traits.is_a?(Hash)
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
      traits = {}
    end

    Artist.create!(
      user: @user,
      name: data["name"],
      genre: data["genre"],
      energy: data["energy"],
      talent: data["talent"],
      traits: traits,
      background: data["background"]
    )
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
      - background: A brief backstory for the artist (1-2 sentences)

      Ensure diversity in all attributes. Provide the response as a valid JSON object.

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
        "background": "The Velveteers are a band from Los Angeles that formed in 2015."
      }
    PROMPT
  end
end

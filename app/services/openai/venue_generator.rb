require "openai"

module OpenAI
  class VenueGenerator
    attr_reader :client

    def initialize
      @client = ::OpenAI::Client.new(
        access_token: Rails.application.credentials.dig(:openai, :api_key) || ENV.fetch("OPENAI_API_KEY", nil),
        request_timeout: 240
      )
    end

    def generate_venues(count = 25)
      # Adjust the count to ensure we get a good distribution across tiers
      tier_counts = {
        1 => (count * 0.3).ceil,  # 30% tier 1
        2 => (count * 0.3).ceil,  # 30% tier 2
        3 => (count * 0.2).ceil,  # 20% tier 3
        4 => (count * 0.15).ceil, # 15% tier 4
        5 => (count * 0.05).ceil  # 5% tier 5
      }

      venues = []

      # Generate venues for each tier
      tier_counts.each do |tier, tier_count|
        venues.concat(generate_tier_venues(tier, tier_count))
      end

      venues
    end

    private

    def generate_tier_venues(tier, count)
      # Define characteristics based on tier
      capacity_range = case tier
      when 1 then [ 30, 100 ]
      when 2 then [ 100, 250 ]
      when 3 then [ 250, 500 ]
      when 4 then [ 500, 2000 ]
      when 5 then [ 2000, 10000 ]
      end

      booking_cost_range = case tier
      when 1 then [ 50, 200 ]
      when 2 then [ 200, 500 ]
      when 3 then [ 500, 1000 ]
      when 4 then [ 1000, 5000 ]
      when 5 then [ 5000, 25000 ]
      end

      prestige_range = case tier
      when 1 then [ 1, 2 ]
      when 2 then [ 3, 5 ]
      when 3 then [ 6, 7 ]
      when 4 then [ 8, 9 ]
      when 5 then [ 10, 10 ]
      end

      # Construct the prompt for this tier
      prompt = construct_prompt(tier, count, capacity_range, booking_cost_range, prestige_range)

      # Call the OpenAI API
      response = client.chat(
        parameters: {
          model: "gpt-4o-mini",
          messages: [
            { role: "system", content: "You are a creative assistant that generates unique and varied venue data for a music management game." },
            { role: "user", content: prompt }
          ],
          temperature: 0.9,
          response_format: { type: "json_object" }
        }
      )

      # Parse the response
      result = JSON.parse(response.dig("choices", 0, "message", "content"))

      # Convert to venue objects
      result["venues"].map do |venue_data|
        {
          name: venue_data["name"],
          capacity: venue_data["capacity"],
          booking_cost: venue_data["booking_cost"],
          prestige: venue_data["prestige"],
          tier: tier,
          description: venue_data["description"],
          preferences: venue_data["preferences"] || {}
        }
      end
    rescue => e
      Rails.logger.error "Error generating venues with OpenAI: #{e.message}"
      # Fall back to static venues if OpenAI fails
      generate_fallback_venues(tier, count)
    end

    def construct_prompt(tier, count, capacity_range, booking_cost_range, prestige_range)
      venue_tiers = {
        1 => "small local venues like coffeehouses, small bars, community centers",
        2 => "mid-sized local venues like clubs, theaters, ballrooms",
        3 => "regional venues like mid-sized concert halls, large clubs, small arenas",
        4 => "large regional or small national venues like concert halls, mid-sized arenas",
        5 => "major national venues like large arenas, stadiums, festival grounds"
      }

      genre_examples = [
        "rock", "indie", "pop", "hip-hop", "rap", "country", "folk", "jazz",
        "blues", "electronic", "dance", "metal", "punk", "alternative", "classical",
        "r&b", "soul", "funk", "reggae", "world", "ambient", "experimental"
      ]

      prompt = <<~PROMPT
        Generate #{count} unique and diverse music venues for tier #{tier} (#{venue_tiers[tier]}).

        Each venue should include:
        - A creative and realistic name
        - Capacity between #{capacity_range[0]} and #{capacity_range[1]} people
        - Booking cost between $#{booking_cost_range[0]} and $#{booking_cost_range[1]}
        - Prestige level between #{prestige_range[0]} and #{prestige_range[1]} (represents the venue's reputation)
        - A brief but vivid description (30-50 words) of the venue's atmosphere, history, and unique characteristics
        - Detailed preferences as a JSON object that may include:
          * preferred_genres: Array of 1-3 music genres the venue specializes in
          * avoided_genres: Array of 0-2 music genres the venue avoids
          * min_artist_popularity: Integer (0-100) representing minimum artist popularity preferred
          * max_artist_popularity: Optional integer (0-100) for venues that prefer underground/up-and-coming artists
          * min_artist_skill: Optional integer (0-100) minimum skill level required
          * preferred_day: Optional string ("monday" through "sunday") if the venue has a special night
          * local_artist_bonus: Optional boolean (true) if the venue has special preference for local artists
          * special_requirements: Optional string describing any unique requirements

        Make the venues extremely diverse and interesting with:
        - Unique architectural features or historical significance
        - Distinct atmospheres (gritty, upscale, quirky, traditional, etc.)
        - Varied audience demographics
        - Different ownership styles (family-owned, corporate, artist collective, etc.)
        - Diverse cultural influences
        - Special features like outdoor spaces, multiple stages, or unique layouts

        Example genres: #{genre_examples.sample(8).join(", ")}

        Return the data as a JSON object with this structure:
        {
          "venues": [
            {
              "name": "Venue Name",
              "capacity": 150,
              "booking_cost": 300,
              "prestige": 3,
              "description": "A vivid description of this unique venue",
              "preferences": {
                "preferred_genres": ["indie rock", "folk"],
                "avoided_genres": ["heavy metal"],
                "min_artist_popularity": 15,
                "min_artist_skill": 30,
                "preferred_day": "thursday",
                "local_artist_bonus": true
              }
            },
            ...
          ]
        }
      PROMPT
    end

    def generate_fallback_venues(tier, count)
      # Static fallback venues in case OpenAI generation fails
      fallback_venues = []

      tier_adjectives = {
        1 => [ "Small", "Cozy", "Intimate", "Local", "Neighborhood" ],
        2 => [ "Hip", "Trendy", "Cool", "Downtown", "Urban" ],
        3 => [ "Popular", "Renowned", "Well-Known", "Established", "Regional" ],
        4 => [ "Famous", "Celebrated", "Premier", "Notable", "Major" ],
        5 => [ "Legendary", "Iconic", "World-Class", "Historic", "Prestigious" ]
      }

      tier_venue_types = {
        1 => [ "Coffee House", "Pub", "Bar", "Basement", "Lounge", "Dive Bar" ],
        2 => [ "Club", "Theater", "Ballroom", "Music Hall", "Venue" ],
        3 => [ "Concert Hall", "Auditorium", "Arena", "Pavilion", "Center" ],
        4 => [ "Amphitheater", "Stadium", "Coliseum", "Forum", "Palace" ],
        5 => [ "Arena", "Stadium", "Dome", "Megaplex", "Festival Grounds" ]
      }

      capacity_range = case tier
      when 1 then [ 30, 100 ]
      when 2 then [ 100, 250 ]
      when 3 then [ 250, 500 ]
      when 4 then [ 500, 2000 ]
      when 5 then [ 2000, 10000 ]
      end

      booking_cost_range = case tier
      when 1 then [ 50, 200 ]
      when 2 then [ 200, 500 ]
      when 3 then [ 500, 1000 ]
      when 4 then [ 1000, 5000 ]
      when 5 then [ 5000, 25000 ]
      end

      prestige_range = case tier
      when 1 then [ 1, 2 ]
      when 2 then [ 3, 5 ]
      when 3 then [ 6, 7 ]
      when 4 then [ 8, 9 ]
      when 5 then [ 10, 10 ]
      end

      count.times do |i|
        adjective = tier_adjectives[tier].sample
        venue_type = tier_venue_types[tier].sample
        name = "The #{adjective} #{venue_type}"

        # Ensure unique names
        name = "#{name} #{i+1}" if fallback_venues.any? { |v| v[:name] == name }

        capacity = rand(capacity_range[0]..capacity_range[1])
        booking_cost = rand(booking_cost_range[0]..booking_cost_range[1])
        prestige = rand(prestige_range[0]..prestige_range[1])

        description = "A #{adjective.downcase} #{venue_type.downcase} with capacity for #{capacity} people. " +
                      "This is a tier #{tier} venue with a prestige rating of #{prestige}."

        fallback_venues << {
          name: name,
          capacity: capacity,
          booking_cost: booking_cost,
          prestige: prestige,
          tier: tier,
          description: description,
          preferences: {
            preferred_genres: [ "rock", "pop" ].sample(rand(1..2)),
            min_artist_popularity: tier * 10,
            min_artist_skill: tier * 5
          }
        }
      end

      fallback_venues
    end
  end
end

# db/seeds/venues.rb
# This file dynamically generates venues using OpenAI GPT

require Rails.root.join('app/services/openai/venue_generator')

puts "Generating venues using OpenAI..."

# Clear existing venues
Venue.destroy_all

begin
  # Initialize the venue generator
  venue_generator = OpenAI::VenueGenerator.new

  # Generate venues (default is 25 distributed across tiers)
  venue_data = venue_generator.generate_venues

  # Create venues from the generated data
  venue_data.each do |venue_attributes|
    Venue.create!(venue_attributes)
  end

  puts "Created #{Venue.count} venues with GPT."
rescue => e
  puts "Error generating venues with GPT: #{e.message}"
  puts "Falling back to static venue data..."

  # Fallback static data in case API fails
  # Tier 1 Venues (Small local venues)
  [
    { name: "The Garage", capacity: 50, booking_cost: 100, prestige: 1, tier: 1, description: "A small garage converted into a performance space. Perfect for new bands." },
    { name: "Coffee House", capacity: 30, booking_cost: 50, prestige: 1, tier: 1, description: "A cozy coffee shop with an open mic night atmosphere." },
    { name: "Corner Bar", capacity: 75, booking_cost: 150, prestige: 2, tier: 1, description: "A local bar with a small stage in the corner." },
    { name: "Community Center", capacity: 100, booking_cost: 200, prestige: 1, tier: 1, description: "A multi-purpose community space available for local events." },
    { name: "College Pub", capacity: 60, booking_cost: 120, prestige: 2, tier: 1, description: "A popular hangout for college students with live music on weekends." }
  ].each do |venue|
    Venue.create!(venue)
  end

  # Tier 2 Venues (Mid-sized local venues)
  [
    { name: "The Underground", capacity: 150, booking_cost: 300, prestige: 3, tier: 2, description: "A basement venue known for its indie rock scene." },
    { name: "Rhythm Room", capacity: 200, booking_cost: 400, prestige: 3, tier: 2, description: "A dedicated music venue with decent sound equipment." },
    { name: "The Loft", capacity: 175, booking_cost: 350, prestige: 4, tier: 2, description: "An upstairs venue with an intimate atmosphere." },
    { name: "Jazz Club", capacity: 125, booking_cost: 250, prestige: 5, tier: 2, description: "A classy venue specializing in jazz and blues." },
    { name: "Rock House", capacity: 225, booking_cost: 450, prestige: 4, tier: 2, description: "A gritty rock venue with character and history." }
  ].each do |venue|
    Venue.create!(venue)
  end

  # Tier 3 Venues (Regional venues)
  [
    { name: "City Hall", capacity: 350, booking_cost: 700, prestige: 6, tier: 3, description: "A converted city hall with excellent acoustics." },
    { name: "The Ballroom", capacity: 400, booking_cost: 800, prestige: 7, tier: 3, description: "An elegant ballroom with a stage and dance floor." },
    { name: "Music Factory", capacity: 450, booking_cost: 900, prestige: 6, tier: 3, description: "An industrial-themed venue popular with alternative bands." },
    { name: "The Forum", capacity: 300, booking_cost: 600, prestige: 7, tier: 3, description: "A mid-sized venue with a strong local following." },
    { name: "Theatre House", capacity: 375, booking_cost: 750, prestige: 8, tier: 3, description: "A renovated theatre with excellent sound quality." }
  ].each do |venue|
    Venue.create!(venue)
  end

  # Tier 4 Venues (Large regional/small national venues)
  [
    { name: "Arena Club", capacity: 800, booking_cost: 1600, prestige: 8, tier: 4, description: "A large club venue that attracts regional touring acts." },
    { name: "The Coliseum", capacity: 1000, booking_cost: 2000, prestige: 9, tier: 4, description: "A warehouse-sized venue with multiple performance areas." },
    { name: "Stadium Bar", capacity: 750, booking_cost: 1500, prestige: 8, tier: 4, description: "A large bar venue with a stage and premium sound system." },
    { name: "Concert Hall", capacity: 1200, booking_cost: 2400, prestige: 9, tier: 4, description: "A proper concert hall with tiered seating and great acoustics." },
    { name: "Pavilion", capacity: 900, booking_cost: 1800, prestige: 9, tier: 4, description: "An indoor/outdoor venue with a large stage." }
  ].each do |venue|
    Venue.create!(venue)
  end

  # Tier 5 Venues (National venues)
  [
    { name: "Mega Arena", capacity: 5000, booking_cost: 10000, prestige: 10, tier: 5, description: "A major arena that hosts national touring acts." },
    { name: "Festival Grounds", capacity: 8000, booking_cost: 16000, prestige: 10, tier: 5, description: "A large outdoor festival space with multiple stages." },
    { name: "The Stadium", capacity: 10000, booking_cost: 20000, prestige: 10, tier: 5, description: "A stadium venue for the biggest acts in the industry." },
    { name: "Convention Center", capacity: 7500, booking_cost: 15000, prestige: 10, tier: 5, description: "A massive convention center with a main arena for concerts." },
    { name: "Amphitheater", capacity: 6000, booking_cost: 12000, prestige: 10, tier: 5, description: "A large amphitheater with excellent natural acoustics." }
  ].each do |venue|
    Venue.create!(venue)
  end

  puts "Created #{Venue.count} venues with static data."
end

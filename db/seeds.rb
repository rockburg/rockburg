# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: "Star Wars" }, { name: "Lord of the Rings" }])
#   Character.create(name: "Luke", movie: movies.first)

# Load all the seed files
Dir[Rails.root.join('db/seeds/*.rb')].sort.each do |file|
  puts "Loading seed file: #{File.basename(file)}"
  load file
end

namespace :db do
  desc "Backfill nano_ids for existing records"
  task backfill_nano_ids: :environment do
    puts "Backfilling nano_ids for existing records..."

    # Models that need nano_ids
    models = [ Artist, ScheduledAction, Season, User, Session ]

    models.each do |model|
      puts "Processing #{model.name}..."
      count = 0

      model.where(nano_id: nil).find_each do |record|
        record.send(:set_nano_id)
        record.save!
        count += 1
        print "." if count % 10 == 0
      end

      puts "\nAdded nano_ids to #{count} #{model.name} records."
    end

    puts "Backfill complete!"
  end
end

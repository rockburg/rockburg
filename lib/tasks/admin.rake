namespace :admin do
  desc "Make a user an admin by email"
  task :create, [ :email ] => :environment do |t, args|
    if args[:email].blank?
      puts "Please provide an email address: rake admin:create[user@example.com]"
      exit
    end

    user = User.find_by(email_address: args[:email])

    if user.nil?
      puts "User with email #{args[:email]} not found"
      exit
    end

    if user.admin?
      puts "User #{user.email_address} is already an admin"
    else
      user.update(admin: true)
      puts "User #{user.email_address} is now an admin"
    end
  end

  desc "List all admin users"
  task list: :environment do
    admins = User.where(admin: true)

    if admins.empty?
      puts "No admin users found"
    else
      puts "Admin users:"
      admins.each do |admin|
        puts "- #{admin.email_address}"
      end
    end
  end
end

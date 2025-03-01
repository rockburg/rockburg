ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "mocha/minitest"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...

    # Helper method to clean the database for tests
    def self.clean_db
      # Delete in the correct order to avoid foreign key constraints
      ScheduledAction.delete_all
      Performance.delete_all
      Transaction.delete_all
      Session.delete_all
      Artist.delete_all
      Venue.delete_all
      Manager.delete_all
      User.delete_all
      Season.delete_all
    end
  end
end

module ActionDispatch
  class IntegrationTest
    def sign_in_as(user)
      post session_url, params: { email_address: user.email_address, password: "password" }
    end
  end
end

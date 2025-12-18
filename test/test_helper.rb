ENV['RACK_ENV'] = 'test'

# Disable ActionCable test helpers to avoid pubsub errors
module ActionCable
  module TestHelper
    def before_setup
      # Skip ActionCable setup
    end
  end
end

require_relative '../config/environment'
require 'minitest/autorun'
require 'minitest/pride'

# Set up test database
ActiveRecord::Base.establish_connection(
  adapter: 'sqlite3',
  database: 'db/test.sqlite3'
)

# Load schema
load 'db/schema.rb'

class Minitest::Test
  # Add more helper methods to be used by all tests here...
  
  def setup
    # Clean up database before each test
    DatabaseCleaner.clean
  end
  
  def teardown
    DatabaseCleaner.clean
  end
end

# Simple DatabaseCleaner implementation
module DatabaseCleaner
  def self.clean
    # Truncate all tables except system tables
    ActiveRecord::Base.connection.tables.each do |table|
      next if table == 'schema_migrations' || table == 'ar_internal_metadata'
      ActiveRecord::Base.connection.execute("DELETE FROM #{table}")
    end
  end
end

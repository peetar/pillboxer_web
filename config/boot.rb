ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __dir__)

require "bundler/setup" # Set up gems listed in the Gemfile.

# Ensure bcrypt is available immediately after bundler setup
begin
  require 'bcrypt'
  puts "✓ BCrypt loaded in boot.rb"
rescue LoadError => e
  puts "✗ Failed to load BCrypt in boot.rb: #{e.message}"
  # This shouldn't happen if bundler/setup worked correctly
  raise e
end
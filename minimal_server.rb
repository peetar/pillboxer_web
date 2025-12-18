#!/usr/bin/env ruby

# Minimal server that avoids bundler conflicts
puts "Starting minimal Pill Boxer server..."

# Load gems directly
begin
  gem 'bcrypt', '~> 3.1.7'
  require 'bcrypt'
  puts "✓ BCrypt loaded successfully"
rescue => e
  puts "✗ Failed to load BCrypt: #{e.message}"
  exit 1
end

begin
  gem 'sqlite3', '~> 1.4'
  require 'sqlite3'
  puts "✓ SQLite3 loaded successfully"
rescue => e
  puts "✗ Failed to load SQLite3: #{e.message}"
  exit 1
end

# Simple test to verify bcrypt works
test_hash = BCrypt::Password.create('test123')
puts "✓ BCrypt test successful: #{test_hash[0..20]}..."

# Load a minimal Rails environment
ENV['RAILS_ENV'] ||= 'development'
require_relative 'config/environment'

puts "✓ Rails environment loaded"

# Test user authentication
begin
  user = User.first
  if user
    puts "✓ User model accessible: #{user.name}"
    if user.authenticate('password123')
      puts "✓ Authentication working"
    else
      puts "✗ Authentication failed"
    end
  else
    puts "✗ No users found"
  end
rescue => e
  puts "✗ User test failed: #{e.message}"
end

# Start simple web server
require 'webrick'

app = Rails.application
server = WEBrick::HTTPServer.new(Port: 3000)
server.mount '/', Rack::Handler::WEBrick, app

trap('INT') { 
  puts "\nShutting down..."
  server.stop 
}

puts "Server running at http://localhost:3000"
puts "Press Ctrl+C to stop"

server.start
#!/usr/bin/env ruby

# Simple Rails server that handles gem loading properly
puts "Starting Pill Boxer Rails Server..."

# Change to the Rails app directory
Dir.chdir(__dir__)

# Set up environment
ENV['RAILS_ENV'] ||= 'development'

# Add the current directory to load path
$LOAD_PATH.unshift(File.expand_path('.', __dir__))

# Load gems manually to avoid bundler conflicts
gem 'rails', '~> 7.1.0'
gem 'sqlite3', '~> 1.4'
gem 'bcrypt', '~> 3.1.7'
gem 'hotwire-rails'
gem 'puma', '~> 6.0'
gem 'sass-rails', '>= 6'
gem 'turbo-rails'
gem 'stimulus-rails'
gem 'jbuilder'
gem 'bootsnap', '>= 1.4.4'

# Now require what we need
require 'bcrypt'
require 'rails/all'
require 'sqlite3'

puts "✓ Gems loaded successfully"

# Load Rails application
require_relative 'config/environment'

puts "✓ Rails application loaded"
puts "Starting WEBrick server on port 3000..."

# Start the server
require 'webrick'
require 'rack'

app = Rails.application
server = WEBrick::HTTPServer.new(
  Port: 3000,
  DocumentRoot: File.join(__dir__, 'public')
)

server.mount '/', Rack::Handler::WEBrick, app

trap('INT') { server.stop }

puts "Pill Boxer server running at http://localhost:3000"
puts "Press Ctrl+C to stop"

server.start
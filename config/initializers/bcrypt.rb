# Load bcrypt early in Rails boot process
puts "Loading bcrypt initializer..."

begin
  require 'bcrypt'
  puts "✓ BCrypt loaded successfully in initializer"
rescue LoadError => e
  puts "✗ Failed to load bcrypt: #{e.message}"
  puts "Attempting to load through bundler..."
  
  begin
    # Ensure bundler is set up
    ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../../Gemfile', __dir__)
    require 'bundler/setup'
    require 'bcrypt'
    puts "✓ BCrypt loaded successfully through bundler"
  rescue => bundler_error
    puts "✗ Failed to load bcrypt through bundler: #{bundler_error.message}"
    raise bundler_error
  end
end
puts "Loading Rails environment..."

begin
  # Set up Bundler environment properly
  ENV['BUNDLE_GEMFILE'] ||= File.expand_path('Gemfile', __dir__)
  require 'bundler/setup'
  
  # Force load all gems to ensure they're available
  Bundler.require(:default)
  
  # Now load Rails
  require_relative 'config/environment'
  puts "✓ Rails environment loaded successfully"
rescue => e
  puts "✗ Error loading Rails environment:"
  puts "  #{e.class}: #{e.message}"
  puts e.backtrace.first(5)
  exit 1
end

if __FILE__ == $0
  puts "Starting Pill Boxer Rails server on port 3000..."
  
  require 'webrick'
  require 'rack'
  require 'rack/handler/webrick'
  
  # Add middleware to catch errors
  app = Rack::Builder.new do
    use Rack::ShowExceptions
    use Rack::Lint
    use Rack::MethodOverride  # Support _method parameter for DELETE/PUT/PATCH
    run Rails.application
  end
  
  puts "Pill Boxer server running at http://localhost:3000"
  puts "Press Ctrl+C to stop"
  
  begin
    Rack::Handler::WEBrick.run(
      app,
      Port: 3000,
      Host: '0.0.0.0',
      Logger: WEBrick::Log.new(STDOUT, WEBrick::Log::DEBUG)
    )
  rescue Interrupt
    puts "\nShutting down server..."
  end
end
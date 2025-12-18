require 'webrick'
require 'rack'

# Simple Rack app for testing
app = Proc.new do |env|
  ['200', {'Content-Type' => 'text/html'}, ['<h1>Hello from Pill Boxer!</h1><p>Basic server is working!</p>']]
end

puts "Starting simple test server on port 3001..."
puts "Visit http://localhost:3001"
puts "Press Ctrl+C to stop"

begin
  Rack::Handler::WEBrick.run(
    app,
    Port: 3001,
    Host: '0.0.0.0'
  )
rescue Interrupt
  puts "\nShutting down server..."
end
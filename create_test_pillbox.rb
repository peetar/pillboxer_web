#!/usr/bin/env ruby
# Test script to verify UI delete works correctly

require_relative 'config/environment'

puts "=== Creating Test Pill Box for UI Delete Test ==="

# Find a user
user = User.find_by(email: 'sarah@example.com')
unless user
  puts "Error: Test user not found"
  exit 1
end

# Create a test pill box
pillbox = Pillbox.create!(
  name: "UI Delete Test Box",
  pillbox_type: 'weekly',
  user: user,
  notes: "Delete this pill box to test the UI delete button"
)

puts "✓ Created pillbox ID #{pillbox.id}"
puts "✓ Name: #{pillbox.name}"
puts "✓ Type: #{pillbox.pillbox_type}"
puts "✓ Compartments: #{pillbox.compartments.count}"
puts
puts "To test the delete button:"
puts "1. Go to http://localhost:3000"
puts "2. Click on '#{pillbox.name}'"
puts "3. Click the Delete button"
puts "4. Confirm the deletion"
puts "5. Verify you're redirected to the dashboard"
puts "6. Verify the pill box no longer appears"
puts
puts "Pillbox URL: http://localhost:3000/pillboxes/#{pillbox.id}"

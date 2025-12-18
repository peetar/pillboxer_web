#!/usr/bin/env ruby
require_relative 'config/environment'

puts "🔄 Testing Pillbox creation..."

# Find or create a test user
user = User.first || User.create!(
  name: 'Test User',
  email: 'test@test.com',
  password: 'password123',
  password_confirmation: 'password123'
)

puts "✓ User: #{user.name}"

# Create a daily pillbox
daily_box = user.pillboxes.create!(
  name: 'My Daily Pillbox',
  pillbox_type: 'daily'
)

puts "\n✓ Created #{daily_box.pillbox_type} pillbox: #{daily_box.name}"
puts "  Compartments: #{daily_box.compartments.count} (will be added via wizard)"
puts "  Adding some sample compartments..."

# Add up to 12 compartments to daily box
sample_times = ['Morning', 'Mid-Morning', 'Noon', 'Afternoon', 'Evening', 'Bedtime']
sample_times.each_with_index do |time, index|
  daily_box.add_compartment(name: time, time_of_day: time.downcase)
  puts "    Added: #{time}"
end

puts "  Total compartments: #{daily_box.compartments.count}"
daily_box.compartments.by_position.each do |c|
  puts "    - #{c.display_name} (position: #{c.position})"
end

# Create a weekly pillbox
weekly_box = user.pillboxes.create!(
  name: 'My Weekly Pillbox',
  pillbox_type: 'weekly'
)

puts "\n✓ Created #{weekly_box.pillbox_type} pillbox: #{weekly_box.name}"
puts "  Compartments: #{weekly_box.compartments.count}"
puts "  Days:"
weekly_box.compartments.by_position.each do |c|
  puts "    - #{c.display_name} (position: #{c.position})"
end

puts "\n✓ All tests passed!"

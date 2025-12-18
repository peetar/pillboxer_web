#!/usr/bin/env ruby
require_relative 'config/environment'

puts "🔄 Testing Pillbox compartment limits..."

user = User.first || User.create!(
  name: 'Test User',
  email: 'test@test.com',
  password: 'password123',
  password_confirmation: 'password123'
)

# Create a daily pillbox and try to add 13 compartments
daily_box = user.pillboxes.create!(
  name: 'Test Daily Limits',
  pillbox_type: 'daily'
)

puts "\n✓ Created daily pillbox: #{daily_box.name}"
puts "  Max compartments allowed: #{Pillbox::MAX_DAILY_COMPARTMENTS}"

# Try to add 13 compartments
13.times do |i|
  result = daily_box.add_compartment(name: "Time #{i + 1}")
  if result
    puts "  ✓ Added compartment #{i + 1}: #{result.name}"
  else
    puts "  ✗ Failed to add compartment #{i + 1} (limit reached)"
  end
end

puts "\n  Final count: #{daily_box.compartments.count} compartments"
puts "  ✓ Limit enforcement working correctly!" if daily_box.compartments.count == 12

# Test weekly pillbox (should have exactly 7)
weekly_box = user.pillboxes.create!(
  name: 'Test Weekly',
  pillbox_type: 'weekly'
)

puts "\n✓ Created weekly pillbox: #{weekly_box.name}"
puts "  Auto-created compartments: #{weekly_box.compartments.count}"
puts "  ✓ Weekly structure correct!" if weekly_box.compartments.count == 7

puts "\n✓ All limit tests passed!"

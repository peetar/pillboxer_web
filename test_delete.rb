#!/usr/bin/env ruby
# Test script to verify delete cascade works correctly

require_relative 'config/environment'

puts "=== Testing Delete Cascade ==="
puts

# Find a user (or create one if needed)
user = User.find_by(email: 'sarah@example.com')
unless user
  puts "Error: Test user not found"
  exit 1
end

puts "Creating test pill box..."
pillbox = Pillbox.create!(
  name: "Test Delete Pill Box",
  pillbox_type: 'daily',
  user: user,
  notes: "This is a test pill box to verify deletion works"
)
puts "✓ Created pillbox ID #{pillbox.id}"

# Add some compartments
puts "\nAdding compartments..."
3.times do |i|
  comp = pillbox.compartments.create!(
    name: "Compartment #{i + 1}",
    position: i + 1,
    time_of_day: "time_#{i + 1}"
  )
  puts "✓ Created compartment ID #{comp.id} - #{comp.name}"
  
  # Add a medication to the compartment
  if user.medications.any?
    med = user.medications.first
    comp.add_medication(med, quantity: 2)
    puts "  ✓ Added medication '#{med.name}' to compartment"
  end
end

# Record counts before deletion
pillbox_id = pillbox.id
compartment_ids = pillbox.compartments.pluck(:id)
compartment_med_count = CompartmentMedication.where(compartment_id: compartment_ids).count

puts "\n=== Before Deletion ==="
puts "Pillbox ID: #{pillbox_id}"
puts "Compartments: #{pillbox.compartments.count}"
puts "Compartment IDs: #{compartment_ids.join(', ')}"
puts "CompartmentMedications: #{compartment_med_count}"

# Delete the pillbox
puts "\n=== Deleting Pillbox ==="
pillbox.destroy
puts "✓ Pillbox.destroy called"

# Check if records were cascade deleted
puts "\n=== After Deletion ==="
remaining_pillbox = Pillbox.find_by(id: pillbox_id)
puts "Pillbox exists: #{remaining_pillbox.present? ? 'YES (ERROR!)' : 'NO (✓)'}"

remaining_compartments = Compartment.where(id: compartment_ids)
puts "Compartments remaining: #{remaining_compartments.count} (should be 0)"

remaining_comp_meds = CompartmentMedication.where(compartment_id: compartment_ids)
puts "CompartmentMedications remaining: #{remaining_comp_meds.count} (should be 0)"

if remaining_pillbox.nil? && remaining_compartments.count == 0 && remaining_comp_meds.count == 0
  puts "\n✅ SUCCESS: All records cascade deleted correctly!"
  exit 0
else
  puts "\n❌ FAILURE: Some records were not deleted"
  exit 1
end

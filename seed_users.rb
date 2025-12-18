#!/usr/bin/env ruby
require_relative 'config/environment'

puts "🔄 Clearing existing data..."
MedicationLog.delete_all
CompartmentMedication.delete_all  
ScheduleMedication.delete_all
Compartment.delete_all
Pillbox.delete_all
Schedule.delete_all
Medication.delete_all
User.delete_all

puts "👥 Creating test users..."

# Create test users with different medication profiles
user1 = User.create!(
  name: "Dr. Sarah Johnson",
  email: "sarah@example.com", 
  password: "password123",
  password_confirmation: "password123"
)

user2 = User.create!(
  name: "Mark Thompson", 
  email: "mark@example.com",
  password: "password123",
  password_confirmation: "password123"
)

user3 = User.create!(
  name: "Lisa Chen",
  email: "lisa@example.com",
  password: "password123", 
  password_confirmation: "password123"
)

puts "💊 Creating medications for each user..."

# User 1 (Sarah) - Heart condition medications
sarah_meds = [
  {
    name: "Lisinopril",
    dosage: "10mg", 
    frequency: "once_daily",
    instructions: "Take with water, preferably in the morning",
    color: "white",
    shape: "round"
  },
  {
    name: "Atorvastatin",
    dosage: "20mg",
    frequency: "once_daily", 
    instructions: "Take in the evening with or without food",
    color: "white",
    shape: "oval"
  }
]

sarah_medications = sarah_meds.map do |med_data|
  user1.medications.create!(med_data)
end

# User 2 (Mark) - Diabetes medications
mark_meds = [
  {
    name: "Metformin",
    dosage: "500mg",
    frequency: "twice_daily",
    instructions: "Take with meals to reduce stomach upset", 
    color: "white",
    shape: "oval"
  },
  {
    name: "Glipizide",
    dosage: "5mg",
    frequency: "once_daily",
    instructions: "Take 30 minutes before breakfast",
    color: "white", 
    shape: "round"
  }
]

mark_medications = mark_meds.map do |med_data|
  user2.medications.create!(med_data)
end

# User 3 (Lisa) - General health medications  
lisa_meds = [
  {
    name: "Vitamin D3",
    dosage: "1000 IU",
    frequency: "once_daily",
    instructions: "Take with food for better absorption",
    color: "yellow",
    shape: "capsule"
  },
  {
    name: "Ibuprofen",
    dosage: "200mg", 
    frequency: "as_needed",
    instructions: "Take with food or milk. Do not exceed 6 tablets per day",
    color: "brown",
    shape: "oval"
  },
  {
    name: "Multivitamin",
    dosage: "1 tablet",
    frequency: "once_daily",
    instructions: "Take with breakfast", 
    color: "multicolor",
    shape: "tablet"
  }
]

lisa_medications = lisa_meds.map do |med_data|
  user3.medications.create!(med_data)
end

puts "📅 Creating schedules for each user..."

# Sarah's heart medication schedule
sarah_schedule = user1.schedules.create!(
  name: "Heart Health Routine",
  schedule_type: "daily",
  active: true
)

sarah_schedule.schedule_medications.create!(
  medication: sarah_medications[0], # Lisinopril
  time_of_day: "morning",
  quantity: 1
)

sarah_schedule.schedule_medications.create!(
  medication: sarah_medications[1], # Atorvastatin  
  time_of_day: "evening",
  quantity: 1
)

# Mark's diabetes schedule
mark_schedule = user2.schedules.create!(
  name: "Diabetes Management", 
  schedule_type: "daily",
  active: true
)

mark_schedule.schedule_medications.create!(
  medication: mark_medications[0], # Metformin
  time_of_day: "morning", 
  quantity: 1
)

mark_schedule.schedule_medications.create!(
  medication: mark_medications[0], # Metformin (twice daily)
  time_of_day: "evening",
  quantity: 1
)

mark_schedule.schedule_medications.create!(
  medication: mark_medications[1], # Glipizide
  time_of_day: "morning",
  quantity: 1
)

# Lisa's wellness schedule
lisa_schedule = user3.schedules.create!(
  name: "Daily Wellness",
  schedule_type: "daily", 
  active: true
)

lisa_schedule.schedule_medications.create!(
  medication: lisa_medications[0], # Vitamin D3
  time_of_day: "morning",
  quantity: 1
)

lisa_schedule.schedule_medications.create!(
  medication: lisa_medications[2], # Multivitamin
  time_of_day: "morning", 
  quantity: 1
)

puts "🗂️  Creating medication logs..."

# Create some recent medication logs for each user
today = Date.current
yesterday = today - 1.day

# Sarah's logs
user1.medication_logs.create!(
  medication: sarah_medications[0],
  taken_at: yesterday.beginning_of_day + 8.hours,
  scheduled_for: yesterday.beginning_of_day + 8.hours,
  taken: true
)

# Mark's logs  
user2.medication_logs.create!(
  medication: mark_medications[0],
  taken_at: today.beginning_of_day + 8.hours,
  scheduled_for: today.beginning_of_day + 8.hours, 
  taken: true
)

# Lisa's logs
user3.medication_logs.create!(
  medication: lisa_medications[0],
  taken_at: today.beginning_of_day + 9.hours,
  scheduled_for: today.beginning_of_day + 9.hours,
  taken: true
)

puts "✅ Seed data created successfully!"
puts "📊 Summary:"
puts "   Users: #{User.count}" 
puts "   Medications: #{Medication.count}"
puts "   Schedules: #{Schedule.count}"
puts "   Schedule Medications: #{ScheduleMedication.count}"
puts "   Medication Logs: #{MedicationLog.count}"
puts ""
puts "🔐 Test login credentials:"
puts "   sarah@example.com / password123"
puts "   mark@example.com / password123" 
puts "   lisa@example.com / password123"
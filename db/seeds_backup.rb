# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

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
    name: "Metformin",
    dosage: "500mg", 
    frequency: "twice_daily",
    instructions: "Take with meals to reduce stomach upset",
    color: "white",
    shape: "oval"
  },
  {
    name: "Vitamin D3",
    dosage: "1000 IU",
    frequency: "once_daily",
    instructions: "Can be taken with or without food",
    color: "yellow",
    shape: "capsule"
  },
  {
    name: "Ibuprofen",
    dosage: "200mg",
    frequency: "as_needed", 
    instructions: "Take as needed for pain or inflammation. Do not exceed 6 tablets in 24 hours",
    color: "brown",
    shape: "round"
  }
]

medications.each do |med_attrs|
  medication = Medication.find_or_create_by(name: med_attrs[:name]) do |m|
    m.dosage = med_attrs[:dosage]
    m.frequency = med_attrs[:frequency]
    m.instructions = med_attrs[:instructions]
    m.color = med_attrs[:color]
    m.shape = med_attrs[:shape]
  end
  
  puts "Created medication: #{medication.name}"
end

# Create a sample daily schedule
daily_schedule = Schedule.find_or_create_by(name: "Daily Routine") do |s|
  s.schedule_type = "daily"
  s.description = "Regular daily medication schedule"
end

# Add medications to the daily schedule
if daily_schedule.schedule_medications.empty?
  lisinopril = Medication.find_by(name: "Lisinopril")
  metformin = Medication.find_by(name: "Metformin")
  vitamin_d = Medication.find_by(name: "Vitamin D3")
  
  daily_schedule.schedule_medications.create!(
    medication: lisinopril,
    time_of_day: "morning",
    quantity: 1
  ) if lisinopril
  
  daily_schedule.schedule_medications.create!(
    medication: metformin,
    time_of_day: "morning", 
    quantity: 1
  ) if metformin
  
  daily_schedule.schedule_medications.create!(
    medication: metformin,
    time_of_day: "evening",
    quantity: 1
  ) if metformin
  
  daily_schedule.schedule_medications.create!(
    medication: vitamin_d,
    time_of_day: "morning",
    quantity: 1
  ) if vitamin_d
  
  puts "Added medications to daily schedule"
end

# Create a sample pillbox for the daily schedule
if daily_schedule.pillboxes.empty?
  pillbox = daily_schedule.pillboxes.create!(
    name: "Daily Pill Organizer",
    pillbox_type: "daily"
  )
  
  puts "Created daily pillbox with #{pillbox.compartments.count} compartments"
end

puts "Seed data created successfully!"
puts "#{Medication.count} medications"
puts "#{Schedule.count} schedules" 
puts "#{Pillbox.count} pillboxes"
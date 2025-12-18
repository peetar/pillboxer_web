#!/usr/bin/env ruby
require_relative 'config/environment'

puts "🔍 Checking database structure..."

# Check what tables exist
tables = ActiveRecord::Base.connection.execute("SELECT name FROM sqlite_master WHERE type='table'").map { |row| row[0] }
puts "Existing tables: #{tables.join(', ')}"

# Check if schema_migrations table exists
if tables.include?('schema_migrations')
  puts "\n📋 Current schema version:"
  versions = ActiveRecord::Base.connection.execute("SELECT version FROM schema_migrations ORDER BY version").map { |row| row[0] }
  puts versions.join(', ')
else
  puts "\n⚠️  No schema_migrations table found. Creating it..."
  ActiveRecord::Base.connection.execute <<-SQL
    CREATE TABLE schema_migrations (
      version VARCHAR NOT NULL PRIMARY KEY
    );
  SQL
end

# Mark our migrations as completed since we already ran them manually
migration_versions = [
  '20251013000001',  # create_medications
  '20251013000002',  # create_schedules 
  '20251013000003',  # create_schedule_medications
  '20251013000004',  # create_pillboxes
  '20251013000005',  # create_compartments
  '20251013000006',  # create_compartment_medications
  '20251013000007',  # create_medication_logs
  '20251013000008',  # create_users
  '20251013000009',  # add_user_id_to_medications
  '20251013000010',  # add_user_id_to_schedules
  '20251013000011',  # add_user_id_to_pillboxes
  '20251013000012'   # add_user_id_to_medication_logs
]

puts "\n✅ Marking migrations as completed..."
migration_versions.each do |version|
  begin
    ActiveRecord::Base.connection.execute("INSERT OR IGNORE INTO schema_migrations (version) VALUES ('#{version}')")
    puts "  ✓ Migration #{version} marked as completed"
  rescue => e
    puts "  ⚠️  Migration #{version}: #{e.message}"
  end
end

puts "\n🎯 Final schema check:"
final_versions = ActiveRecord::Base.connection.execute("SELECT version FROM schema_migrations ORDER BY version").map { |row| row[0] }
puts "Schema versions: #{final_versions.join(', ')}"
puts "\n✅ Database migrations are now synchronized!"
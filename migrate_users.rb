#!/usr/bin/env ruby
require_relative 'config/environment'

# Run migrations manually
ActiveRecord::Base.connection.execute <<-SQL
  CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    email TEXT NOT NULL UNIQUE,
    password_digest TEXT NOT NULL,
    active BOOLEAN DEFAULT 1,
    last_login_at DATETIME,
    created_at DATETIME NOT NULL,
    updated_at DATETIME NOT NULL
  );
SQL

ActiveRecord::Base.connection.execute <<-SQL
  CREATE INDEX IF NOT EXISTS index_users_on_email ON users(email);
SQL

ActiveRecord::Base.connection.execute <<-SQL
  CREATE INDEX IF NOT EXISTS index_users_on_active ON users(active);
SQL

# Add user_id columns to existing tables
begin
  ActiveRecord::Base.connection.execute "ALTER TABLE medications ADD COLUMN user_id INTEGER REFERENCES users(id)"
  ActiveRecord::Base.connection.execute "CREATE INDEX index_medications_on_user_id ON medications(user_id)"
  ActiveRecord::Base.connection.execute "CREATE INDEX index_medications_on_user_id_and_name ON medications(user_id, name)"
rescue ActiveRecord::StatementInvalid => e
  puts "Medications user_id column may already exist: #{e.message}"
end

begin
  ActiveRecord::Base.connection.execute "ALTER TABLE schedules ADD COLUMN user_id INTEGER REFERENCES users(id)"
  ActiveRecord::Base.connection.execute "CREATE INDEX index_schedules_on_user_id ON schedules(user_id)"
  ActiveRecord::Base.connection.execute "CREATE INDEX index_schedules_on_user_id_and_name ON schedules(user_id, name)"
rescue ActiveRecord::StatementInvalid => e
  puts "Schedules user_id column may already exist: #{e.message}"
end

begin
  ActiveRecord::Base.connection.execute "ALTER TABLE pillboxes ADD COLUMN user_id INTEGER REFERENCES users(id)"
  ActiveRecord::Base.connection.execute "CREATE INDEX index_pillboxes_on_user_id ON pillboxes(user_id)"
  ActiveRecord::Base.connection.execute "CREATE INDEX index_pillboxes_on_user_id_and_name ON pillboxes(user_id, name)"
rescue ActiveRecord::StatementInvalid => e
  puts "Pillboxes user_id column may already exist: #{e.message}"
end

begin
  ActiveRecord::Base.connection.execute "ALTER TABLE medication_logs ADD COLUMN user_id INTEGER REFERENCES users(id)"
  ActiveRecord::Base.connection.execute "CREATE INDEX index_medication_logs_on_user_id ON medication_logs(user_id)"
  ActiveRecord::Base.connection.execute "CREATE INDEX index_medication_logs_on_user_id_and_taken_at ON medication_logs(user_id, taken_at)"
rescue ActiveRecord::StatementInvalid => e
  puts "MedicationLogs user_id column may already exist: #{e.message}"
end

puts "✓ User tables and associations created successfully"
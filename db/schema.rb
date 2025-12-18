# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2025_12_11_220448) do
  create_table "compartment_medications", force: :cascade do |t|
    t.integer "compartment_id", null: false
    t.integer "medication_id", null: false
    t.integer "quantity", default: 1
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["compartment_id", "medication_id"], name: "idx_on_compartment_id_medication_id_b736fccacb"
    t.index ["compartment_id"], name: "index_compartment_medications_on_compartment_id"
    t.index ["medication_id"], name: "index_compartment_medications_on_medication_id"
  end

  create_table "compartments", force: :cascade do |t|
    t.integer "pillbox_id", null: false
    t.string "name", null: false
    t.integer "position", null: false
    t.string "day_of_week"
    t.string "time_of_day"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["day_of_week"], name: "index_compartments_on_day_of_week"
    t.index ["pillbox_id", "position"], name: "index_compartments_on_pillbox_id_and_position", unique: true
    t.index ["pillbox_id"], name: "index_compartments_on_pillbox_id"
    t.index ["time_of_day"], name: "index_compartments_on_time_of_day"
  end

  create_table "medication_logs", force: :cascade do |t|
    t.integer "medication_id", null: false
    t.datetime "scheduled_for", null: false
    t.datetime "taken_at"
    t.boolean "taken", default: false
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.index ["medication_id", "scheduled_for"], name: "index_medication_logs_on_medication_id_and_scheduled_for"
    t.index ["medication_id"], name: "index_medication_logs_on_medication_id"
    t.index ["scheduled_for"], name: "index_medication_logs_on_scheduled_for"
    t.index ["taken"], name: "index_medication_logs_on_taken"
    t.index ["user_id", "taken_at"], name: "index_medication_logs_on_user_id_and_taken_at"
    t.index ["user_id"], name: "index_medication_logs_on_user_id"
  end

  create_table "medications", force: :cascade do |t|
    t.string "name", null: false
    t.string "dosage", null: false
    t.string "frequency", null: false
    t.text "instructions"
    t.boolean "active", default: true
    t.string "color"
    t.string "shape"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.index ["active"], name: "index_medications_on_active"
    t.index ["name"], name: "index_medications_on_name"
    t.index ["user_id", "name"], name: "index_medications_on_user_id_and_name"
    t.index ["user_id"], name: "index_medications_on_user_id"
  end

  create_table "pillboxes", force: :cascade do |t|
    t.integer "schedule_id"
    t.string "name", null: false
    t.string "pillbox_type", null: false
    t.date "week_starting"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.datetime "last_filled_at"
    t.text "notes"
    t.index ["pillbox_type"], name: "index_pillboxes_on_pillbox_type"
    t.index ["schedule_id"], name: "index_pillboxes_on_schedule_id"
    t.index ["user_id", "name"], name: "index_pillboxes_on_user_id_and_name"
    t.index ["user_id"], name: "index_pillboxes_on_user_id"
    t.index ["week_starting"], name: "index_pillboxes_on_week_starting"
  end

  create_table "schedule_medications", force: :cascade do |t|
    t.integer "schedule_id", null: false
    t.integer "medication_id", null: false
    t.string "time_of_day", null: false
    t.integer "quantity", default: 1
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["medication_id"], name: "index_schedule_medications_on_medication_id"
    t.index ["schedule_id", "medication_id"], name: "index_schedule_medications_on_schedule_id_and_medication_id"
    t.index ["schedule_id"], name: "index_schedule_medications_on_schedule_id"
    t.index ["time_of_day"], name: "index_schedule_medications_on_time_of_day"
  end

  create_table "schedules", force: :cascade do |t|
    t.string "name", null: false
    t.string "schedule_type", null: false
    t.boolean "active", default: true
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.index ["active"], name: "index_schedules_on_active"
    t.index ["schedule_type"], name: "index_schedules_on_schedule_type"
    t.index ["user_id", "name"], name: "index_schedules_on_user_id_and_name"
    t.index ["user_id"], name: "index_schedules_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.text "name", null: false
    t.text "email", null: false
    t.text "password_digest", null: false
    t.boolean "active", default: true
    t.datetime "last_login_at", precision: nil
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["active"], name: "index_users_on_active"
    t.index ["email"], name: "index_users_on_email"
  end

  add_foreign_key "compartment_medications", "compartments"
  add_foreign_key "compartment_medications", "medications"
  add_foreign_key "compartments", "pillboxes"
  add_foreign_key "medication_logs", "medications"
  add_foreign_key "medication_logs", "users"
  add_foreign_key "medications", "users"
  add_foreign_key "pillboxes", "schedules"
  add_foreign_key "pillboxes", "users"
  add_foreign_key "schedule_medications", "medications"
  add_foreign_key "schedule_medications", "schedules"
  add_foreign_key "schedules", "users"
end

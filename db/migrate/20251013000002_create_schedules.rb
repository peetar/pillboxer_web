class CreateSchedules < ActiveRecord::Migration[7.1]
  def change
    create_table :schedules do |t|
      t.string :name, null: false
      t.string :schedule_type, null: false
      t.boolean :active, default: true
      t.text :description
      
      t.timestamps
    end
    
    add_index :schedules, :schedule_type
    add_index :schedules, :active
  end
end
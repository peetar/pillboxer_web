class CreateScheduleMedications < ActiveRecord::Migration[7.1]
  def change
    create_table :schedule_medications do |t|
      t.references :schedule, null: false, foreign_key: true
      t.references :medication, null: false, foreign_key: true
      t.string :time_of_day, null: false
      t.integer :quantity, default: 1
      
      t.timestamps
    end
    
    add_index :schedule_medications, [:schedule_id, :medication_id]
    add_index :schedule_medications, :time_of_day
  end
end
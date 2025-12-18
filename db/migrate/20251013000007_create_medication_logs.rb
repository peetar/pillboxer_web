class CreateMedicationLogs < ActiveRecord::Migration[7.1]
  def change
    create_table :medication_logs do |t|
      t.references :medication, null: false, foreign_key: true
      t.datetime :scheduled_for, null: false
      t.datetime :taken_at
      t.boolean :taken, default: false
      t.text :notes
      
      t.timestamps
    end
    
    add_index :medication_logs, :scheduled_for
    add_index :medication_logs, :taken
    add_index :medication_logs, [:medication_id, :scheduled_for]
  end
end
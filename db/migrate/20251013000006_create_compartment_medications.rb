class CreateCompartmentMedications < ActiveRecord::Migration[7.1]
  def change
    create_table :compartment_medications do |t|
      t.references :compartment, null: false, foreign_key: true
      t.references :medication, null: false, foreign_key: true
      t.integer :quantity, default: 1
      
      t.timestamps
    end
    
    add_index :compartment_medications, [:compartment_id, :medication_id]
  end
end
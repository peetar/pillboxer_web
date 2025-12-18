class CreateMedications < ActiveRecord::Migration[7.1]
  def change
    create_table :medications do |t|
      t.string :name, null: false
      t.string :dosage, null: false
      t.string :frequency, null: false
      t.text :instructions
      t.boolean :active, default: true
      t.string :color
      t.string :shape
      
      t.timestamps
    end
    
    add_index :medications, :name
    add_index :medications, :active
  end
end
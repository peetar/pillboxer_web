class CreateCompartments < ActiveRecord::Migration[7.1]
  def change
    create_table :compartments do |t|
      t.references :pillbox, null: false, foreign_key: true
      t.string :name, null: false
      t.integer :position, null: false
      t.string :day_of_week
      t.string :time_of_day
      
      t.timestamps
    end
    
    add_index :compartments, [:pillbox_id, :position], unique: true
    add_index :compartments, :day_of_week
    add_index :compartments, :time_of_day
  end
end
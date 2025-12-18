class CreatePillboxes < ActiveRecord::Migration[7.1]
  def change
    create_table :pillboxes do |t|
      t.references :schedule, null: false, foreign_key: true
      t.string :name, null: false
      t.string :pillbox_type, null: false
      t.date :week_starting
      
      t.timestamps
    end
    
    add_index :pillboxes, :pillbox_type
    add_index :pillboxes, :week_starting
  end
end
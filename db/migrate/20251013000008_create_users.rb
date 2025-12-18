class CreateUsers < ActiveRecord::Migration[7.1]
  def change
    create_table :users do |t|
      t.string :name, null: false
      t.string :email, null: false
      t.string :password_digest, null: false
      t.boolean :active, default: true
      t.datetime :last_login_at
      
      t.timestamps
    end
    
    add_index :users, :email, unique: true
    add_index :users, :active
  end
end
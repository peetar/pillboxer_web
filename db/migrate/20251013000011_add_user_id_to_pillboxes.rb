class AddUserIdToPillboxes < ActiveRecord::Migration[7.1]
  def change
    add_reference :pillboxes, :user, null: false, foreign_key: true
    add_index :pillboxes, [:user_id, :name]
  end
end
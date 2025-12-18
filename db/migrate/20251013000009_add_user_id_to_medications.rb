class AddUserIdToMedications < ActiveRecord::Migration[7.1]
  def change
    add_reference :medications, :user, null: false, foreign_key: true
    add_index :medications, [:user_id, :name]
  end
end
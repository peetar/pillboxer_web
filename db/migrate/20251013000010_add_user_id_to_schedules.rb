class AddUserIdToSchedules < ActiveRecord::Migration[7.1]
  def change
    add_reference :schedules, :user, null: false, foreign_key: true
    add_index :schedules, [:user_id, :name]
  end
end
class AddUserIdToMedicationLogs < ActiveRecord::Migration[7.1]
  def change
    add_reference :medication_logs, :user, null: false, foreign_key: true
    add_index :medication_logs, [:user_id, :taken_at]
  end
end
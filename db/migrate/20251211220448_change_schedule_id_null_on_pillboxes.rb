class ChangeScheduleIdNullOnPillboxes < ActiveRecord::Migration[7.1]
  def change
    change_column_null :pillboxes, :schedule_id, true
  end
end

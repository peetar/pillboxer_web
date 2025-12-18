class AddLastFilledToPillboxes < ActiveRecord::Migration[7.1]
  def change
    add_column :pillboxes, :last_filled_at, :datetime
    add_column :pillboxes, :notes, :text
  end
end

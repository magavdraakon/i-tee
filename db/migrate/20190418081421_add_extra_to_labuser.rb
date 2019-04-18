class AddExtraToLabuser < ActiveRecord::Migration[5.2]
  def change
    add_column :lab_users, :extra, :text
  end
end

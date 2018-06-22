class AddLastActivityToLabuser < ActiveRecord::Migration[5.2]
  def change
    add_column :lab_users, :last_activity, :datetime
    add_column :lab_users, :activity, :string
  end
end

class AddGuacamoleUserIdToLabUser < ActiveRecord::Migration[5.2]
  def change
    add_column :lab_users, :g_user, :integer
    add_column :lab_users, :g_username, :string, default: ''
    add_column :lab_users, :g_password, :string, default: ''
  end
end

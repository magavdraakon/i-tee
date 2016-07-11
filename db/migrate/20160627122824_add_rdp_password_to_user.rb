class AddRdpPasswordToUser < ActiveRecord::Migration
  def change
    add_column :users, :rdp_password, :string, default: ''
  end
end

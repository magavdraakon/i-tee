class AddRdpPasswordToUser < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :rdp_password, :string, default: ''
  end
end

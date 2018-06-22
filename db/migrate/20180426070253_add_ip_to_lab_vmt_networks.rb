class AddIpToLabVmtNetworks < ActiveRecord::Migration[5.2]
  def change
    add_column :lab_vmt_networks, :ip, :string
  end
end

class AddIpToLabVmtNetworks < ActiveRecord::Migration
  def change
    add_column :lab_vmt_networks, :ip, :string
  end
end

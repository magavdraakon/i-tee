class VmAddPwd < ActiveRecord::Migration[5.2]
  def self.up
    add_column :vms, :password, :string
  end

  def self.down
    remove_column :vms, :password
  end
end

class VmAddPwd < ActiveRecord::Migration
  def self.up
    add_column :vms, :password, :string
  end

  def self.down
    remove_column :vms, :password
  end
end

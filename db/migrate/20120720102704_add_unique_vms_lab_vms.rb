class AddUniqueVmsLabVms < ActiveRecord::Migration
  def self.up
    add_index :vms, :name, :unique => true
    add_index :lab_vmts, :name, :unique => true
  end

  def self.down
    remove_index "vms", :name => "index_vms_on_name"
    remove_index "lab_vmts", :name => "index_lab_vmts_on_name"
  end
end

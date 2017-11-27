class RemoveVmUserReference < ActiveRecord::Migration
  def self.up
    remove_column :vms, :user_id
  end

  def self.down
    add_column :vms, :user_id, :integer
  end
end

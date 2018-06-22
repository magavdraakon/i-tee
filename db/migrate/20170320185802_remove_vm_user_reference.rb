class RemoveVmUserReference < ActiveRecord::Migration[5.2]
  def self.up
    remove_column :vms, :user_id
  end

  def self.down
    add_column :vms, :user_id, :integer
  end
end

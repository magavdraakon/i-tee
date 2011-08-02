class AddProgressToVms < ActiveRecord::Migration
  def self.up
    add_column :vms, :progress, :text
  end

  def self.down
    remove_column :vms, :progress
  end
end

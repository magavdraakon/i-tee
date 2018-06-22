class AddProgressToVms < ActiveRecord::Migration[5.2]
  def self.up
    add_column :vms, :progress, :text
  end

  def self.down
    remove_column :vms, :progress
  end
end

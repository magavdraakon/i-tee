class OptimisticLockMac < ActiveRecord::Migration[5.2]
  def self.up
    add_column :macs, :lock_version, :integer, :default => 0
  end

  def self.down
    remove_column :macs, :lock_version
  end
end

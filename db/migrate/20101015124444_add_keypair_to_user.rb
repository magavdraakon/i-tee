class AddKeypairToUser < ActiveRecord::Migration
  def self.up
    add_column :users, :keypair, :bool
  end

  def self.down
    remove_column :users, :name
  end
end

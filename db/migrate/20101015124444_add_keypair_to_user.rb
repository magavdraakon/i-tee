class AddKeypairToUser < ActiveRecord::Migration
  def self.up
    add_column :users, :keypair, :boolean
  end

  def self.down
    remove_column :users, :keypair
  end
end

class AddTokenExpire < ActiveRecord::Migration[5.2]
  def self.up
    add_column :users, :token_expires, :datetime
  end

  def self.down
    remove_column :users, :token_expires
  end
end

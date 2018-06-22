class AddTokenAuth < ActiveRecord::Migration[5.2]
  def self.up
    add_column :users, :authentication_token, :string
  end

  def self.down
     remove_column :users, :authentication_token
  end
end

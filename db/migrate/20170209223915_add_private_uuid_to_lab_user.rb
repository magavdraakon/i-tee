class AddPrivateUuidToLabUser < ActiveRecord::Migration
  def change
    add_column :lab_users, :private_uuid, :string, :unique => true, :null => true, :default => nil
  end
end

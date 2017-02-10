class AddUidToLabuser < ActiveRecord::Migration
  def change
    add_column :lab_users, :uuid, :string
    add_index :lab_users, :uuid, :unique => true
    add_index :assistants, :uri, :unique => true
  end
end

class MakeEmailNullAndUnique < ActiveRecord::Migration
  def up
    change_column :users, :email, :string, :null => true, :unique => true, :default => nil
  end
  def down
    change_column :users, :email, :string, :null => false, :unique => false, :default => ""
  end
end

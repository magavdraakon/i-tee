class AddUserLdapFlag < ActiveRecord::Migration[5.2]
  def self.up
    # by default all users are ldap users
    add_column :users, :ldap, :boolean, :default => true
  end

  def self.down
    remove_column :users, :ldap
  end
end

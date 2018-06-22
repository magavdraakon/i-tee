class RemoveUnusedColumns < ActiveRecord::Migration[5.2]
  def up
    remove_column :vmts, :operating_system_id
    remove_column :vmts, :shellinabox
    remove_column :vms, :progress
    remove_column :lab_users, :progress
    remove_column :users, :keypair
    drop_table :operating_systems
  end
end

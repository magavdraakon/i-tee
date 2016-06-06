class AddGuacamoleConnectionIdToVms < ActiveRecord::Migration
  def change
    add_column :vms, :g_connection, :integer
  end
end

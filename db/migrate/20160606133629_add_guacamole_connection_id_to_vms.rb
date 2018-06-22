class AddGuacamoleConnectionIdToVms < ActiveRecord::Migration[5.2]
  def change
    add_column :vms, :g_connection, :integer
  end
end

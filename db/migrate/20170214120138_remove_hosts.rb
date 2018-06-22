class RemoveHosts < ActiveRecord::Migration[5.2]
  def up
    drop_table :hosts
  end
end

class RemoveHosts < ActiveRecord::Migration
  def up
    drop_table :hosts
  end
end

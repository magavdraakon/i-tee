class RemoveMacs < ActiveRecord::Migration
  def change
    drop_table :macs
  end
end

class RemoveMacs < ActiveRecord::Migration[5.2]
  def change
    drop_table :macs
  end
end

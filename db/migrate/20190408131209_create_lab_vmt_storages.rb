class CreateLabVmtStorages < ActiveRecord::Migration[5.2]
  def change
    create_table :lab_vmt_storages do |t|
    	t.integer :storage_id
    	t.integer :lab_vmt_id
      t.string :controller
      t.integer :port
      t.integer :device
      t.string :mount

      t.timestamps
    end
  end
end

class CreateLabVmtNetworks < ActiveRecord::Migration[5.2]
  def change
    create_table :lab_vmt_networks do |t|
      t.integer :network_id
      t.integer :slot
      t.integer :lab_vmt_id
      t.boolean :promiscuous
      t.boolean :reinit_mac

      t.timestamps
    end

    add_index :lab_vmt_networks, [:lab_vmt_id, :network_id, :slot], unique: true

  end
end

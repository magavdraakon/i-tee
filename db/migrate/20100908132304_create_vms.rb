class CreateVms < ActiveRecord::Migration[5.2]
  def self.up
    create_table :vms do |t|
      t.string :name
      t.string :image_id
      t.integer :lab_id
      t.integer :ram
      t.integer :hdd
      t.integer :nic_count

      t.timestamps
    end
  end

  def self.down
    drop_table :vms
  end
end

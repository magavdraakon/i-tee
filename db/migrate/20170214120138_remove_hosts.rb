class RemoveHosts < ActiveRecord::Migration
  def up
    drop_table :hosts
  end
  def down
    create_table :hosts do |t|
      t.string :name
      t.string :ip
      t.text :publickey
      t.text :privatekey
      t.integer :ram
      t.integer :cpu_cores
      t.integer :hdd
      t.integer :priority
      t.timestamps
  end
end

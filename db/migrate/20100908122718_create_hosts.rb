class CreateHosts < ActiveRecord::Migration
  def self.up
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

  def self.down
    drop_table :hosts
  end
end

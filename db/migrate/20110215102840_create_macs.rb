class CreateMacs < ActiveRecord::Migration
  def self.up
    create_table :macs do |t|
      t.string :mac
      t.string :ip
      t.integer :vm_id

      t.timestamps
    end
  end

  def self.down
    drop_table :macs
  end
end

class CreateLabVmts < ActiveRecord::Migration
  def self.up
    create_table :lab_vmts do |t|
      t.string :name
      t.integer :lab_id
      t.integer :vmt_id

      t.timestamps
    end
  end

  def self.down
    drop_table :lab_vmts
  end
end

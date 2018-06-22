class RedefineVm < ActiveRecord::Migration[5.2]
  def self.up
      drop_table :vms #drop old table and create the new one
    create_table :vms do |t|
      t.string :name, :unique => true #specific virtual machine name must be unique
      t.integer :lab_vmt_id #template from lab_vmts
     # t.integer :lab_id #this can be acessed trough template_id
      #t.string :mac
      #t.string :ip #these two will be given trough a relation from Mac table
      t.integer :user_id
      t.text :description

      t.timestamps
    end
  end

  def self.down
     drop_table :vms #drop the new table and re-create the old one
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
end

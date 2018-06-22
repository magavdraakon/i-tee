class CreateVmts < ActiveRecord::Migration[5.2]
  def self.up
    create_table :vmts do |t|
      t.string :image
      t.string :xml_script
      t.text :private

      t.timestamps
    end
  end

  def self.down
    drop_table :vmts
  end
end

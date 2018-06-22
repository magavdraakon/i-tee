class CreateMaterials < ActiveRecord::Migration[5.2]
  def self.up
    create_table :materials do |t|
      t.string :name
      t.text :source

      t.timestamps
    end
  end

  def self.down
    drop_table :materials
  end
end

class CreateLabMaterials < ActiveRecord::Migration
  def self.up
    create_table :lab_materials do |t|
      t.integer :lab_id
      t.integer :material_id
      t.text :description
      t.integer :sort

      t.timestamps
    end
  end

  def self.down
    drop_table :lab_materials
  end
end

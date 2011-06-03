class CreateOperatingSystems < ActiveRecord::Migration
  def self.up
    create_table :operating_systems do |t|
      t.string :name
      t.string :icon
      t.text :connection_help

      t.timestamps
    end
  end

  def self.down
    drop_table :operating_systems
  end
end

class CreateLabs < ActiveRecord::Migration[5.2]
  def self.up
    create_table :labs do |t|
      t.string :name
      t.text :description

      t.timestamps
    end
  end

  def self.down
    drop_table :labs
  end
end

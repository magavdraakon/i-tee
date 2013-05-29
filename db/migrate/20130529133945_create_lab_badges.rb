class CreateLabBadges < ActiveRecord::Migration
  def change
    create_table :lab_badges do |t|
      t.integer :lab_id
      t.integer :badge_id
      t.string :name
	  t.text :description
      t.timestamps
    end
    add_index :lab_badges, [:lab_id, :name], :unique => true
  end
end

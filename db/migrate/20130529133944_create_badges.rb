class CreateBadges < ActiveRecord::Migration
  def change
    create_table :badges do |t|
      t.string :icon
      t.string :placeholder

      t.timestamps
    end
  end
end
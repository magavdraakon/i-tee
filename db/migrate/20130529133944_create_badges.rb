class CreateBadges < ActiveRecord::Migration[5.2]
  def change
    create_table :badges do |t|
      t.string :icon
      t.string :placeholder

      t.timestamps
    end
  end
end

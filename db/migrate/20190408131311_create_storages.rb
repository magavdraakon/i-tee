class CreateStorages < ActiveRecord::Migration[5.2]
  def change
    create_table :storages do |t|
      t.string :storage_type
      t.string :path
      t.boolean :enabled

      t.timestamps
    end
  end
end

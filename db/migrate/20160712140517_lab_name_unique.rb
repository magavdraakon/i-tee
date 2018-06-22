class LabNameUnique < ActiveRecord::Migration[5.2]
  def up
  	add_index :labs, :name, :unique => true
  end

  def down
  end
end

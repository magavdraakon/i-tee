class LabNameUnique < ActiveRecord::Migration
  def up
  	add_index :labs, :name, :unique => true
  end

  def down
  end
end

class AddShortDescToLab < ActiveRecord::Migration
  def self.up
    add_column :labs, :short_description, :string
  end

  def self.down
    remove_column :labs, :short_description
  end
end

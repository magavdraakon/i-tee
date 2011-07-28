class LabUserProgressToText < ActiveRecord::Migration
  def self.up
    change_column :lab_users, :progress, :text, :limit => nil

  end

  def self.down
    change_column :lab_users, :progress, :string
  end
end

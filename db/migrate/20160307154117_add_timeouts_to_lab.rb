class AddTimeoutsToLab < ActiveRecord::Migration[5.2]
  def change
    add_column :labs, :poll_freq, :integer, :default => 0 # disabled
    add_column :labs, :end_timeout, :integer, :default => 0 # disabled
    add_column :labs, :power_timeout, :integer, :default => 0 # disabled
  end
end

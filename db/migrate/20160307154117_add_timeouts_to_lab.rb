class AddTimeoutsToLab < ActiveRecord::Migration
  def change
    add_column :labs, :poll_freq, :integer, :default => 10*60 # 10 minutes
    add_column :labs, :end_timeout, :integer, :default => 0 # no timeout
    add_column :labs, :power_timeout, :integer, :default => 45*60 # 45 minutes
  end
end

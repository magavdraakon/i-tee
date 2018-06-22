class AddPingThresholdsToLab < ActiveRecord::Migration[5.2]
  def change
    add_column :labs, :ping_low, :integer, default: 100 # value < good
    add_column :labs, :ping_mid, :integer, default: 300 # value < usable
    add_column :labs, :ping_high, :integer, default: 600 # value < bad & value > connection error
  end
end

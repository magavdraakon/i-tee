class AddEnableRdpToLabVmt < ActiveRecord::Migration
  def change
    add_column :lab_vmts, :enable_rdp, :boolean, default: true
  end
end

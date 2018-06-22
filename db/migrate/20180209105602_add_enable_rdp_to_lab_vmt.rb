class AddEnableRdpToLabVmt < ActiveRecord::Migration[5.2]
  def change
    add_column :lab_vmts, :enable_rdp, :boolean, default: true
  end
end

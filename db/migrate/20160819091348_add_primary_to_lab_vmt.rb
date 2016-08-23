class AddPrimaryToLabVmt < ActiveRecord::Migration
  def change
    add_column :lab_vmts, :primary, :boolean, default: false
  end
end

class AddPrimaryToLabVmt < ActiveRecord::Migration[5.2]
  def change
    add_column :lab_vmts, :primary, :boolean, default: false
  end
end

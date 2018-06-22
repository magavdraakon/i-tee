class AddGuacamoleFlagsToLabVmt < ActiveRecord::Migration[5.2]
  def change
    add_column :lab_vmts, :g_type, :integer, default: 0
  end
end

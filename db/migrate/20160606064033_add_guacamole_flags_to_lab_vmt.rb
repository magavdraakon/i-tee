class AddGuacamoleFlagsToLabVmt < ActiveRecord::Migration
  def change
    add_column :lab_vmts, :g_type, :integer, default: 0
  end
end

class AddOrderToLabVmt < ActiveRecord::Migration
  def change
    add_column :lab_vmts, :position, :integer, :default => 0
  end
end

class AddAllowRestartToVm < ActiveRecord::Migration[5.2]
  def change
    add_column :lab_vmts, :allow_restart, :boolean, default: true
  end
end

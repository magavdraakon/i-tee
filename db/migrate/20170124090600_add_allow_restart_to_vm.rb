class AddAllowRestartToVm < ActiveRecord::Migration
  def change
    add_column :lab_vmts, :allow_restart, :boolean, default: true
  end
end

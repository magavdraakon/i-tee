class AddVmsByOneAllToLabs < ActiveRecord::Migration
  def change
    add_column :labs, :vms_by_one, :boolean,  :default=> true
  end
end

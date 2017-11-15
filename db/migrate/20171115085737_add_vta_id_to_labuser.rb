class AddVtaIdToLabuser < ActiveRecord::Migration
  def change
    add_column :lab_users, :vta_id, :string
    add_column :assistants, :version, :string, default: 'v1'  
 end
end

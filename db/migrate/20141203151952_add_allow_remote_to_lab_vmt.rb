class AddAllowRemoteToLabVmt < ActiveRecord::Migration
  def change
    add_column :lab_vmts, :allow_remote, :boolean, :default=> true
  end
end

class AddAllowRemoteToLabVmt < ActiveRecord::Migration[5.2]
  def change
    add_column :lab_vmts, :allow_remote, :boolean, :default=> true
  end
end

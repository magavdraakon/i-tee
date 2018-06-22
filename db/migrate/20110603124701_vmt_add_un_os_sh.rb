class VmtAddUnOsSh < ActiveRecord::Migration[5.2]
  def self.up
    add_column :vmts, :username, :string
    add_column :vmts, :operating_system_id, :integer
    add_column :vmts, :shellinabox, :boolean
  end

  def self.down
    remove_column :vmts, :username
    remove_column :vmts, :os_id
    remove_column :vmts, :shellinabox
  end
end

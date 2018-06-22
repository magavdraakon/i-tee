class RemoveXmlScriptAndPrivate < ActiveRecord::Migration[5.2]
  def up
    remove_column :vmts, :xml_script
    remove_column :vmts, :private
  end
end

class RemoveXmlScriptAndPrivate < ActiveRecord::Migration
  def up
    remove_column :vmts, :xml_script
    remove_column :vmts, :private
  end
end

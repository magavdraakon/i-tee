class AddVersionToAssistant < ActiveRecord::Migration
  def change
    add_column :assistants, :version, :string, default: 'v1'  
 end
end

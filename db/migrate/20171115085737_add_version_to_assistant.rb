class AddVersionToAssistant < ActiveRecord::Migration[5.2]
  def change
    add_column :assistants, :version, :string, default: 'v1'  
 end
end

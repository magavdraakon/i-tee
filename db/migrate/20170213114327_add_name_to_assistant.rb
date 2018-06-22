class AddNameToAssistant < ActiveRecord::Migration[5.2]
  def change
    add_column :assistants, :name, :string
  end
end

class AddAssistantSetupFlagToLabUser < ActiveRecord::Migration[5.2]
  def change
    add_column :lab_users, :vta_setup, :boolean, default: false
  end
end

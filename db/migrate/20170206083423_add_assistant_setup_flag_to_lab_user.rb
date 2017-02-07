class AddAssistantSetupFlagToLabUser < ActiveRecord::Migration
  def change
    add_column :lab_users, :vta_setup, :boolean, default: false
  end
end

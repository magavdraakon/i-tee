class AddAssistantValuesToLabUser < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :user_key, :string
  end
end

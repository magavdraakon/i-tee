class AddRestartableToLabs < ActiveRecord::Migration[5.2]
  def change
    add_column :labs, :restartable, :boolean,  :default=> true
  end
end

class AddRestartableToLabs < ActiveRecord::Migration
  def change
    add_column :labs, :restartable, :boolean,  :default=> true
  end
end

class AddStartAllToLabs < ActiveRecord::Migration
  def change
    add_column :labs, :startAll, :boolean,  :default=> false

  end
end

class AddStartAllToLabs < ActiveRecord::Migration[5.2]
  def change
    add_column :labs, :startAll, :boolean,  :default=> false

  end
end

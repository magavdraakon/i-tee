class AddEndableToLabs < ActiveRecord::Migration
  def change
    add_column :labs, :endable, :boolean,  :default=> true
  end
end

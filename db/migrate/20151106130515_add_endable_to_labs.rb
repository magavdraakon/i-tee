class AddEndableToLabs < ActiveRecord::Migration[5.2]
  def change
    add_column :labs, :endable, :boolean,  :default=> true
  end
end

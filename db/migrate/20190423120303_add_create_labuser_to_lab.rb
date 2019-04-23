class AddCreateLabuserToLab < ActiveRecord::Migration[5.2]
  def change
    add_column :labs, :create_labuser, :boolean, default: true
  end
end

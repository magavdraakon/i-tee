class AddHostToLab < ActiveRecord::Migration
  def change
  	add_column :labs, :host_id, :integer
  end
end

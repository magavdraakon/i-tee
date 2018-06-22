class AddHostToLab < ActiveRecord::Migration[5.2]
  def change
  	add_column :labs, :host_id, :integer
  end
end

class AddConfigToLab < ActiveRecord::Migration[5.2]
  def change
    add_column :labs, :config, :text
  end
end

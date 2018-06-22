class AddExposeUuidToLabVmt < ActiveRecord::Migration[5.2]
  def change
    add_column :lab_vmts, :expose_uuid, :boolean
  end
end

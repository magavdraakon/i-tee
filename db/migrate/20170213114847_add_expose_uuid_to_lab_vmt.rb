class AddExposeUuidToLabVmt < ActiveRecord::Migration
  def change
    add_column :lab_vmts, :expose_uuid, :boolean
  end
end

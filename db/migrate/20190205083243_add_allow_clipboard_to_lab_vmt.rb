class AddAllowClipboardToLabVmt < ActiveRecord::Migration[5.2]
  def change
    add_column :lab_vmts, :allow_clipboard, :boolean, default: true
  end
end
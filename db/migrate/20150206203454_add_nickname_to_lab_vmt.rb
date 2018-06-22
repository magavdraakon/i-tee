class AddNicknameToLabVmt < ActiveRecord::Migration[5.2]
  def change
    add_column :lab_vmts, :nickname, :string
  end
end

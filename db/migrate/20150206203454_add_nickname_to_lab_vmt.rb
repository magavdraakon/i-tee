class AddNicknameToLabVmt < ActiveRecord::Migration
  def change
    add_column :lab_vmts, :nickname, :string
  end
end

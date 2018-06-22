class AddAssistantValuesToLab < ActiveRecord::Migration[5.2]
  def change
    add_column :labs, :lab_hash, :string
    add_column :labs, :lab_token, :string
    add_column :labs, :assistant_id, :integer
  end
end

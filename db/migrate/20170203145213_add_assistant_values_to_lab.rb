class AddAssistantValuesToLab < ActiveRecord::Migration
  def change
    add_column :labs, :lab_hash, :string
    add_column :labs, :lab_token, :string
    add_column :labs, :assistant_id, :integer
  end
end

class AddUidToLabuser < ActiveRecord::Migration[5.2]
  def change
    add_column :lab_users, :uuid, :string
    add_index :lab_users, :uuid, :unique => true

    # reset class ref
    LabUser.reset_column_information
    # add uuid to old labusers
    LabUser.all.each do |lu|
    	lu.uuid = SecureRandom.uuid
    	lu.save
    end

    add_index :assistants, :uri, :unique => true
  end
end

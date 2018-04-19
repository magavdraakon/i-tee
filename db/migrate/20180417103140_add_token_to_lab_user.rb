class AddTokenToLabUser < ActiveRecord::Migration
  def change
    add_column :lab_users, :token, :string
    add_index :lab_users, :token, :unique => true

    # reset class ref
    LabUser.reset_column_information
    # add token to old labusers
    LabUser.all.each do |lu|
    	lu.token = SecureRandom.uuid if lu.token.blank?
    	lu.save
    end
  end
end

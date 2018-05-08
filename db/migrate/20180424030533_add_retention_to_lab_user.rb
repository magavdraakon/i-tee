class AddRetentionToLabUser < ActiveRecord::Migration
  def change
  	add_column :lab_users, :coupon_id, :integer
  	add_column :lab_users, :retention_time, :datetime
  end
end

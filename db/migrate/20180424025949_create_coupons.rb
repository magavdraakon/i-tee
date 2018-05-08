class CreateCoupons < ActiveRecord::Migration
  def change
    create_table :coupons do |t|
      t.string :name
      t.string :redeemcode
      t.datetime :valid_from
      t.datetime :valid_through
      t.integer :retention
      t.integer :usage
      t.references :lab
      t.references :user

      t.timestamps
    end
    add_index :coupons, :lab_id
    add_index :coupons, :user_id
  end
end

class CreateLabUsers < ActiveRecord::Migration
  def self.up
    create_table :lab_users do |t|
      t.integer :lab_id
      t.integer :user_id
      t.string :progress
      t.string :result
      t.datetime :start
      t.datetime :pause
      t.datetime :end

      t.timestamps
    end
  end

  def self.down
    drop_table :lab_users
  end
end

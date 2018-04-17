class CreateLabuserConnections < ActiveRecord::Migration
  def change
    create_table :labuser_connections do |t|
      t.integer :lab_user_id
      t.datetime :start_at
      t.datetime :end_at

      t.timestamps
    end
  end
end

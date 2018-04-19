class CreateLabuserConnections < ActiveRecord::Migration
  def change
    create_table :labuser_connections do |t|
      t.integer :lab_user_id
      t.integer :start_at, :limit => 8   # bigint (8 bytes)
      t.integer :end_at, :limit => 8   # bigint (8 bytes)

      t.timestamps
    end
  end
end

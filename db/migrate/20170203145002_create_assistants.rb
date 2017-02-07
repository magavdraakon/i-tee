class CreateAssistants < ActiveRecord::Migration
  def change
    create_table :assistants do |t|
      t.string :uri, :unique => true
      t.boolean :enabled, default: true

      t.timestamps
    end
  end
end

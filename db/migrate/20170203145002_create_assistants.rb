class CreateAssistants < ActiveRecord::Migration[5.2]
  def change
    create_table :assistants do |t|
      t.string :uri, :unique => true
      t.boolean :enabled, default: true

      t.timestamps
    end
  end
end

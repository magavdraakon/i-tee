# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20131014133943) do

  create_table "badges", :force => true do |t|
    t.string   "icon"
    t.string   "placeholder"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "ckeditor_assets", :force => true do |t|
    t.string   "data_file_name",                                 :null => false
    t.string   "data_content_type"
    t.integer  "data_file_size"
    t.integer  "assetable_id"
    t.string   "assetable_type",    :limit => 30
    t.string   "type",              :limit => 25
    t.string   "guid",              :limit => 10
    t.integer  "locale",            :limit => 1,  :default => 0
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "ckeditor_assets", ["assetable_type", "assetable_id"], :name => "fk_assetable"
  add_index "ckeditor_assets", ["assetable_type", "type", "assetable_id"], :name => "idx_assetable_type"
  add_index "ckeditor_assets", ["user_id"], :name => "fk_user"

  create_table "hosts", :force => true do |t|
    t.string   "name"
    t.string   "ip"
    t.text     "publickey"
    t.text     "privatekey"
    t.integer  "ram"
    t.integer  "cpu_cores"
    t.integer  "hdd"
    t.integer  "priority"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "lab_badges", :force => true do |t|
    t.integer  "lab_id"
    t.integer  "badge_id"
    t.string   "name"
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "lab_badges", ["lab_id", "name"], :name => "index_lab_badges_on_lab_id_and_name", :unique => true

  create_table "lab_users", :force => true do |t|
    t.integer  "lab_id"
    t.integer  "user_id"
    t.text     "progress"
    t.string   "result"
    t.datetime "start"
    t.datetime "pause"
    t.datetime "end"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "lab_vmts", :force => true do |t|
    t.string   "name"
    t.integer  "lab_id"
    t.integer  "vmt_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "lab_vmts", ["name"], :name => "index_lab_vmts_on_name", :unique => true

  create_table "labs", :force => true do |t|
    t.string   "name"
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "short_description"
  end

  create_table "macs", :force => true do |t|
    t.string   "mac"
    t.string   "ip"
    t.integer  "vm_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "lock_version", :default => 0
  end

  create_table "materials", :force => true do |t|
    t.string   "name"
    t.text     "source"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "operating_systems", :force => true do |t|
    t.string   "name"
    t.string   "icon"
    t.text     "connection_help"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "user_badges", :force => true do |t|
    t.integer  "user_id"
    t.integer  "lab_badge_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", :force => true do |t|
    t.string   "email",                               :default => "",   :null => false
    t.string   "encrypted_password",   :limit => 128, :default => "",   :null => false
    t.string   "password_salt",                       :default => "",   :null => false
    t.string   "reset_password_token"
    t.string   "remember_token"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                       :default => 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "username"
    t.string   "name"
    t.boolean  "keypair"
    t.string   "authentication_token"
    t.datetime "token_expires"
    t.boolean  "ldap",                                :default => true
  end

  add_index "users", ["reset_password_token"], :name => "index_users_on_reset_password_token", :unique => true
  add_index "users", ["username"], :name => "index_users_on_username", :unique => true

  create_table "vms", :force => true do |t|
    t.string   "name"
    t.integer  "lab_vmt_id"
    t.integer  "user_id"
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "password"
    t.text     "progress"
  end

  add_index "vms", ["name"], :name => "index_vms_on_name", :unique => true

  create_table "vmts", :force => true do |t|
    t.string   "image"
    t.string   "xml_script"
    t.text     "private"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "username"
    t.integer  "operating_system_id"
    t.boolean  "shellinabox"
  end

end

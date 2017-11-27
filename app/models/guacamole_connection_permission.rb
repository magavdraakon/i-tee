class GuacamoleConnectionPermission < ActiveRecord::Base
	establish_connection "#{Rails.env}_guacamole"
	self.table_name = "guacamole_connection_permission" 

	self.primary_keys = [ :user_id, :connection_id, :permission ]

	belongs_to :guacamole_user, class_name: 'GuacamoleUser', foreign_key: 'user_id'
	belongs_to :guacamole_connection, class_name: 'GuacamoleConnection', foreign_key: 'connection_id'
end


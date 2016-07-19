class GuacamoleConnectionPermission < ActiveRecord::Base
	establish_connection "#{Rails.env}_guacamole"
	self.table_name = "guacamole_connection_permission" 

	belongs_to :guacamole_connection, class_name: 'GuacamoleConnection', foreign_key: 'connection_id'
	belongs_to :guacamole_user, class_name: 'GuacamoleUser', foreign_key: 'user_id'
end


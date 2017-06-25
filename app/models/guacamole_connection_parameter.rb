class GuacamoleConnectionParameter < ActiveRecord::Base
	establish_connection "#{Rails.env}_guacamole"
	self.table_name = "guacamole_connection_parameter" 

	self.primary_keys = [ :connection_id, :parameter_name ]

	belongs_to :guacamole_connection, class_name: 'GuacamoleConnection', foreign_key: 'connection_id'
end


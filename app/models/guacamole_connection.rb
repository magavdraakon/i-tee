require "base64"

class GuacamoleConnection < ActiveRecord::Base
	establish_connection "#{Rails.env}_guacamole"
	self.table_name = "guacamole_connection" 

	has_many :guacamole_connection_parameters, class_name: 'GuacamoleConnectionParameter', primary_key: 'connection_id', foreign_key: 'connection_id'
	has_many :guacamole_connection_permissions, class_name: 'GuacamoleConnectionPermission', primary_key: 'connection_id', foreign_key: 'connection_id'

	
	def self.get_url(id)
		# TODO: get full url? host from config
=begin
The characters after "/guacamole/client/" are not encrypted data. They are a base64 string which is produced from the concatenation of:
* The connection identifier
* The type (c for connections and g for balancing groups)
* The identifier of the auth provider storing the connection data (usually postgresql, mysql, or ldap, depending on what auth backend you are using)
Each of these components separated from the other by a single NULL character (U+0000), with the resulting string encoded with base64.
=end
		type = 'c' # connection type
		case connection.adapter_name
			when 'MySQL', 'MySQL2'
				db = 'mysql'
			when 'PostgreSQL'
				db = 'postgresql'
			else
				raise 'Unknown database type'
		end
 		Base64.encode64("#{id}\0#{type}\0#{db}").strip
	end

	def add_parameters(arg)
		arg.each do |param|
			self.guacamole_connection_parameters.create(param)
		end
	end

end


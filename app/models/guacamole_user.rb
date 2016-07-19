class GuacamoleUser < ActiveRecord::Base
	establish_connection "#{Rails.env}_guacamole"
	self.table_name = "guacamole_user" 

	has_many :guacamole_connection_permissions, class_name: 'GuacamoleConnectionPermission', primary_key: 'user_id', foreign_key: 'user_id'

	before_create :apply_salt

	def apply_salt
		self.password_salt = GuacamoleUser.select('UNHEX(SHA2(UUID(), 256)) as salt').first.salt
		self.password_hash = GuacamoleUser.select("UNHEX(SHA2(CONCAT('#{self.password_hash}', HEX('#{self.password_salt}')), 256)) as password_hash").first.password_hash
	end
end


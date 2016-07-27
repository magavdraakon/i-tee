class GuacamoleUser < ActiveRecord::Base
	establish_connection "#{Rails.env}_guacamole"
	self.table_name = "guacamole_user" 

	has_many :guacamole_connection_permissions, class_name: 'GuacamoleConnectionPermission', primary_key: 'user_id', foreign_key: 'user_id'

	before_create :apply_salt

	def apply_salt
		self.password_salt = SecureRandom.random_bytes(32)
		salt_hex = self.password_salt.unpack('H*').first.upcase
		self.password_hash = Digest::SHA256.digest "#{self.password_hash}#{salt_hex}";
	end
end

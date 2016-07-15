class Guacamole < ActiveRecord::Base
	# TODO: move values to config
  @@client = Mysql2::Client.new(
  		:host => ITee::Application::config.guacamole_db_host, 
  		:username => ITee::Application::config.guacamole_db_user, 
  		:password => ITee::Application::config.guacamole_db_pass, 
  		:database => ITee::Application::config.guacamole_db_name, 
  		:port=>ITee::Application::config.guacamole_db_port)

# add user and return id on success (id will be bound to lab_user)
	def self.insert_user(username, password)
		s_result = @@client.query("SELECT UNHEX(SHA2(UUID(), 256)) as salt")
		salt = s_result.first['salt']
		# todo: failed insert auto increments primary key. check for duplicate before insert? or live with id gaps?
		#statement = @@client.prepare("INSERT INTO guacamole_user (username, password_hash, password_salt, timezone ) VALUES (?,  UNHEX(SHA2(CONCAT(?, HEX(?)), 256)), ?, ?)")
		#result = statement.execute(username, password, salt, salt, 'Etc/GMT+0')

		e_username = @@client.escape(username.to_s)
		e_password = @@client.escape(password.to_s)
		result = @@client.query("INSERT INTO guacamole_user (username, password_hash, password_salt, timezone ) VALUES ('#{e_username}',  UNHEX(SHA2(CONCAT('#{e_password}', HEX('#{salt}')), 256)), '#{salt}', 'Etc/GMT+0')")

		id = @@client.last_id

		{ id: id }
		rescue Exception => e
  			{ error: e}
	end

	def self.find_user_by_username(username)
		#statement = @@client.prepare("SELECT * FROM guacamole_user where username=?") 
		#result = statement.execute(username)
		escaped = @@client.escape(username.to_s)
		result = @@client.query("SELECT * FROM guacamole_user where username='#{escaped}'")
		result.first
	end

	def self.find_user_by_id(user_id)
		#statement = @@client.prepare("SELECT * FROM guacamole_user where user_id=?") 
		#result = statement.execute(user_id)
		escaped = @@client.escape(user_id.to_s)
		result = @@client.query("SELECT * FROM guacamole_user where user_id=#{escaped}")
		result.first
	end
# remove user by id
	def self.remove_user(user_id)
		# remove user
		#statement = @@client.prepare("DELETE FROM guacamole_user where user_id=?") 
		#result = statement.execute(user_id)
		escaped = @@client.escape(user_id.to_s)
		result = @@client.query("DELETE FROM guacamole_user where user_id=#{escaped}")

		# remove user connections
		#statement = @@client.prepare("DELETE FROM guacamole_connection_permission where user_id=?") 
		#result = statement.execute(user_id)
		result = @@client.query("DELETE FROM guacamole_connection_permission where user_id=#{escaped}")
	end

# add connection and return id
	def self.insert_connection(data)
		# data format {connection_name, protocol, max_connections, max_connections_per_user, params {hostname, port, username, password, color-depth}}
		# insert connection
		#statement = @@client.prepare("INSERT INTO guacamole_connection (connection_name, protocol, max_connections, max_connections_per_user) VALUES (?, ?, ?, ?)") 
		#result = statement.execute(data[:connection_name], data[:protocol], data[:max_connections], data[:max_connections_per_user])

		e_name = @@client.escape(data[:connection_name].to_s)
		e_protocol = @@client.escape(data[:protocol].to_s)
		e_max = @@client.escape(data[:max_connections].to_s)
		e_maxp = @@client.escape(data[:max_connections_per_user].to_s)
		result = @@client.query("INSERT INTO guacamole_connection (connection_name, protocol, max_connections, max_connections_per_user) VALUES ('#{e_name}', '#{e_protocol}', #{e_max}, #{e_maxp})")

		# get new connection id
		conn_id = @@client.last_id
		# insert parameters for connection 1-by-1
		#s = @@client.prepare("INSERT INTO guacamole_connection_parameter (connection_id, parameter_name, parameter_value) VALUES (?, ?, ?)") 
		# guacamole_connection_parameter : hostname, password, port, username, color-depth ...
		data[:params].keys.each do | k |
			puts "#{k} - #{data[:params][k]}"
			#r = s.execute(conn_id, "#{k}", data[:params][k])
			e_k = @@client.escape("#{k}".to_s)
			e_v = @@client.escape(data[:params][k].to_s)
			r = @@client.query("INSERT INTO guacamole_connection_parameter (connection_id, parameter_name, parameter_value) VALUES (#{conn_id}, '#{e_k}', '#{e_v}')")
		end
		# return connection id
		{id: conn_id}
		rescue Exception => e
  			{ error: e}
	end

	def self.update_parameter(connection_id, parameter_name, parameter_value)
		# check if parameter is set

		#s = @@client.prepare("SELECT * FROM guacamole_connection_parameter WHERE connection_id = ? AND parameter_name = ?")
		#r = s.execute(connection_id, parameter_name)

		e_id = @@client.escape(connection_id.to_s)
		e_k = @@client.escape(parameter_name.to_s)
		e_v = @@client.escape(parameter_value.to_s)
		r = @@client.query("SELECT * FROM guacamole_connection_parameter WHERE connection_id = #{e_id} AND parameter_name = '#{e_k}'")

		par = r.first
		if par
			# update
			#s = @@client.prepare("UPDATE guacamole_connection_parameter SET parameter_value = ? WHERE connection_id = ? AND parameter_name = ?") 
			#r = s.execute(parameter_value, connection_id, parameter_name)
			r = @@client.query("UPDATE guacamole_connection_parameter SET parameter_value = '#{e_v}' WHERE connection_id = #{e_id} AND parameter_name = '#{e_k}'")
			@@client.affected_rows
		else
			# insert
			#s = @@client.prepare("INSERT INTO guacamole_connection_parameter (connection_id, parameter_name, parameter_value) VALUES (?, ?, ?)") 
			#r = s.execute(connection_id, parameter_name, parameter_value)
			r = @@client.query("INSERT INTO guacamole_connection_parameter (connection_id, parameter_name, parameter_value) VALUES (#{e_id}, '#{e_k}', '#{e_v}')")
			@@client.affected_rows
		end
		rescue Exception => e
  			{ error: e}
	end

	def self.get_url(id) # TODO: get full url? host from config
=begin
The characters after "/guacamole/client/" are not encrypted data. They are a base64 string which is produced from the concatenation of:
* The connection identifier
* The type (c for connections and g for balancing groups)
* The identifier of the auth provider storing the connection data (usually postgresql, mysql, or ldap, depending on what auth backend you are using)
Each of these components separated from the other by a single NULL character (U+0000), with the resulting string encoded with base64.
=end
		type = 'c' # connection type
		db = 'mysql' # db server type
		require "base64"
 		Base64.encode64("#{id}\0#{type}\0#{db}").strip
	end

	def self.find_connection_by_name(connection_name)
		# find connection by name
		#statement = @@client.prepare("SELECT * FROM guacamole_connection WHERE connection_name=?") 
		#result = statement.execute(connection_name)
		e_name = @@client.escape(connection_name.to_s)
		result = @@client.query("SELECT * FROM guacamole_connection WHERE connection_name='#{e_name}'")
		conn = result.first
		if conn
			conn[:params]={}
			# get connection parameters and add them to the connection object
			#statement = @@client.prepare("SELECT * FROM guacamole_connection_parameter WHERE connection_id=?") 
			#result = statement.execute(conn['connection_id'])
			e_id = @@client.escape(conn['connection_id'].to_s)
			result = @@client.query("SELECT * FROM guacamole_connection_parameter WHERE connection_id=#{e_id}")
			# add to connection
			result.each do |row|
				conn[:params][row['parameter_name']] = row['parameter_value']
			end
			conn
		else
			false
		end
		rescue Exception => e
			puts e
  			false
	end
	def self.find_connection_by_id(connection_id)
		# find connection by name
		#statement = @@client.prepare("SELECT * FROM guacamole_connection WHERE connection_id=?") 
		#result = statement.execute(connection_id)

		e_id = @@client.escape(connection_id.to_s)
		result = @@client.query("SELECT * FROM guacamole_connection WHERE connection_id=#{e_id}")

		conn = result.first
		if conn
			conn[:params]={}
			# get connection parameters and add them to the connection object
			#statement = @@client.prepare("SELECT * FROM guacamole_connection_parameter WHERE connection_id=?") 
			#result = statement.execute(conn['connection_id'])
			e_id = @@client.escape(conn['connection_id'].to_s)
			result = @@client.query("SELECT * FROM guacamole_connection_parameter WHERE connection_id=#{e_id}")
			# add to connection
			result.each do |row|
				conn[:params][row['parameter_name']] = row['parameter_value']
			end
			conn
		else
			false
		end
		rescue Exception => e
			puts e
  			false
	end

# remove connection by id
	def self.remove_connection(connection_id)
		# remove conection by id
		#statement = @@client.prepare("DELETE FROM guacamole_connection where connection_id=?") 
		#result = statement.execute(connection_id)
		e_id = @@client.escape(connection_id.to_s)
		result = @@client.query("DELETE FROM guacamole_connection where connection_id=#{e_id}")
		# remove connection parameters 
		#statement = @@client.prepare("DELETE FROM guacamole_connection_parameter where connection_id=?" 
		#result = statement.execute(connection_id)
		result = @@client.query("DELETE FROM guacamole_connection_parameter where connection_id=#{e_id}")
		
		# remove connection permissions
		#statement = @@client.prepare("DELETE FROM guacamole_connection_permission where connection_id=?") 
		#result = statement.execute(connection_id)
		result = @@client.query("DELETE FROM guacamole_connection_permission where connection_id=#{e_id}")
		true
		rescue Exception => e
  			{ error: e}
	end

# allow user to connect to a connetion (vm)
	def self.allow_connection(user_id, connection_id)
		# check if already allowed
		#statement = @@client.prepare("SELECT * FROM guacamole_connection_permission where user_id = ? and connection_id = ? and permission = ?") 
		#result = statement.execute(user_id, connection_id, 'READ')

		e_id = @@client.escape(connection_id.to_s)
		e_uid = @@client.escape(user_id.to_s)
		result = @@client.query("SELECT * FROM guacamole_connection_permission where user_id = #{e_uid} and connection_id = #{e_id} and permission = 'READ' ")

		conn = result.first
		if conn
			{id: conn['connection_id']}
		else
			# allow connection
			# guacamole_connection_permission : user_id, connection_id, READ
			#statement = @@client.prepare("INSERT INTO guacamole_connection_permission (user_id, connection_id, permission) VALUES (?, ?, ?)") 
			#result = statement.execute(user_id, connection_id, 'READ')
			result = @@client.query("INSERT INTO guacamole_connection_permission (user_id, connection_id, permission) VALUES (#{e_uid}, #{e_id}, 'READ' )")

			per_id = @@client.affected_rows
			{id: per_id}
		end
		rescue Exception => e
  			{ error: e}
	end

	def self.disallow_connection(user_id, connection_id)
		# guacamole_connection_permission : user_id, connection_id, READ
		#statement = @@client.prepare("DELETE FROM guacamole_connection_permission WHERE user_id = ? and connection_id = ?") 
		#result = statement.execute(user_id, connection_id)

		e_id = @@client.escape(connection_id.to_s)
		e_uid = @@client.escape(user_id.to_s)
		result = @@client.query("DELETE FROM guacamole_connection_permission WHERE user_id = #{e_uid} and connection_id = #{e_id}")
		true
		rescue Exception => e
  			{ error: e}
	end
end
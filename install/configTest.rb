#!/usr/bin/env ruby
begin
	require 'rubygems'
rescue LoadError
	leave('Run: sudo apt-get install rubygems',1)
end
begin
	require 'json'
rescue LoadError
	leave('Run: gem install json',1)
end

filename = ARGV[0] || '/etc/i-tee/config.yaml'

file = File.read(filename);
@data = JSON.parse(file).to_hash

def leave(message, code)
	puts message 
	exit code
end

# fields without default values
template = {
	"database": {
					"adapter": "mysql2",
					"host": "host.local",
					"username": "itee",
					"password": "password",
					"database": "itee"
	},
	"guacamole_database": {
					"adapter": "mysql2",
					"host": "host.local",
					"username": "guacamole",
					"password": "password",
					"database": "guacamole"
	},
	"guacamole": {
					"url_prefix": "https://host.local/guacamole",
					#"cookie_domain": "hostname", # defaults to ''
					#"prefix":"dev", # defaults to dev
					"rdp_host": "host.local"
	},
	"ldap": {
					"host": "host.local",
					"port": 3890,
					#"attribute": "sAMAccountName", # deafults to uid
					"base": "dc=zentyal-domain,dc=lan",
					"group_base": "cn=Users,dc=zentyal-domain,dc=lan",
					#"ssl": false, # defaults to false
					"user": "username",
					"password": "password"
	},
	#"skin": "EIK", # defaults to EIK
	#"per_page": 15, # defaults to 15
	#"admins":[], # defaults to []
	#"managers":[], # defaults to []
	"rdp_host": "hostname",
	"development": true
}

# check 1. level
diff = (template.keys.map{|l|l.to_s} - @data.keys)
if diff.count>0
	leave("config is missing field(s) #{diff.join(', ')}", 1)
end

# check 2. level
template.each do |key, level|
	if level.is_a?(Hash)
		diff = (level.keys.map{|l|l.to_s} - @data[key.to_s].keys)
		if diff.count>0
			leave("config '#{key}' is missing field(s) #{diff.join(', ')}", 1)
		end
	end
end

leave("config has all needed fields", 0)

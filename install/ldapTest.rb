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
begin
	require 'net/ldap'
rescue LoadError
  leave('Run: gem install net-ldap',1)
end

filename = ARGV[0] || '/etc/i-tee/config.yaml'

file = File.read(filename);
@data = JSON.parse(file)

def leave(message, code)
	puts message 
	exit code
end

ldap = Net::LDAP.new
ldap.host = @data['ldap']['host']
ldap.port = @data['ldap']['port']
ldap.auth @data['ldap']['user'], @data['ldap']['password']
if ldap.bind
  # authentication succeeded
  leave('bind successful', 0)
else
  # authentication failed
  leave('bind failed', 1)
end
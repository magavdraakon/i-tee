class GuacamoleDbBase < ActiveRecord::Base  
  self.abstract_class = true
  establish_connection GUACAMOLE_DB
end  
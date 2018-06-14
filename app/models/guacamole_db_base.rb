class GuacamoleDbBase < ActiveRecord::Base  
  self.abstract_class = true
  establish_connection ITee::Application.config.database["#{Rails.env}_guacamole"]
end  
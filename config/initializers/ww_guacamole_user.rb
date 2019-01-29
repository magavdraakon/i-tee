# check if user with the username in guacamole config is set
# if it is not set create it to avoid username stealing
if Rails.application.config.respond_to?(:guacamole2)
	unless user = User.where(username: Rails.application.config.guacamole2['username'] ).first
		Rails.logger.debug "CREATE User for guacamole-proxy admin"
		User.create!(username: Rails.application.config.guacamole2['username'], password: Rails.application.config.guacamole2['password'], email: "#{Rails.application.config.guacamole2['username']}@host.local", name:"guacamole admin")
	else
		Rails.logger.debug "UPDATE User for guacamole-proxy admin"
		user.update!(username: Rails.application.config.guacamole2['username'], password: Rails.application.config.guacamole2['password'], email: "#{Rails.application.config.guacamole2['username']}@host.local", name:"guacamole admin")
	end
end
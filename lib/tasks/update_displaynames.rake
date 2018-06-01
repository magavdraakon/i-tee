namespace :ldapusers do
  desc "Fixes student names for UNI-ID LDAP users"
  task :updatename => :environment do

  	# Find users who have name same as username
  	updated = 0
    users = User.where("username = name and ldap = 1").each do |user|
    	begin
    	user.name = Devise::LDAP::Adapter.get_ldap_param(user.username,"displayname").first
    	if user.save
    		puts "Name updated for #{user.username}: #{user.name}"
    		updated+=1
    	end
    	rescue NoMethodError 
    		puts "Could not find name for #{user.username}"
    	end
    end
    puts "Updated #{updated} users"
  end
end

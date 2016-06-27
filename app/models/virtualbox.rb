class Virtualbox < ActiveRecord::Base

# this is a class to activate different command-line vboxmanage commands and translate the results for the rails app


# create the password hash to be fed to the set_password method
def self.create_password_hash(username, password)
	info = %x(sudo -u vbox VBoxManage internalcommands passwordhash #{password} | cut -f 3 -d' ')
	status= $?
	#logger.debug info
	if status.exitstatus===0
		"VBoxAuthSimple/users/#{username} #{info}".strip
	else
		logger.debug "vboxmanage failed with errror code #{status.exitstatus}"
		false
	end
end

# set password for vms
# TODO: allow sending a list of vm-s instead of applying to all machines
def self.set_password(hash)
	info = %x(sudo -u vbox VBoxManage list vms| cut -f1 -d' '| tr -d '"' )
	status = $?
	error=false
	# logger.debug info
	info.split(/\n+/).each do |line|
		#puts "vm is: #{line}"
		ex = %x(sudo -u vbox VBoxManage setextradata #{line} #{hash})
		st = $?
		#puts line
		#puts st
		#puts ex
		unless st.exitstatus===0
			error=true
			logger.debug "setting new RDP password for #{line} failed \n"
		end
	end
	logger.debug "set new password for "+info.split(/\n+/).count.to_s+" machines"
	!error
end

def self.unset_password(username)
	info = %x(sudo -u vbox VBoxManage list vms| cut -f1 -d' '| tr -d '"' )
	status = $?
	error=false
	# logger.debug info
	info.split(/\n+/).each do |line|
		#puts "vm is: #{line}"
		ex = %x(sudo -u vbox VBoxManage setextradata #{line} VBoxAuthSimple/users/#{username} )
		st = $?
		#puts line
		#puts st
		#puts ex
		unless st.exitstatus===0
			error=true
			logger.debug "unsetting new RDP password for #{line} failed \n"
		end
	end
	logger.debug "unset password for "+info.split(/\n+/).count.to_s+" machines"
	!error
end

end
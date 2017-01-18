class Check 
	

	# get free memory
	def self.get_memory

	end

	# get free disk
	def self.get_disk

	end

	# t/f has minimal memory and disk space to run average lab
	def self.has_free_resources
		# check if script file exists. if it does not exist return true by default
		# call a script to evaluate if the host has enough free memory and disk space
=begin
		info = %x(sudo -Hu vbox VBoxManage list runningvms | cut -f2 -d'"')
		status= $?
		#logger.debug info
		if status.exitstatus===0
			info.split(/\n+/)
		else
			false
		end	
=end
		# TODO: does the script respond 0/1 or some value?
		{success: true, message: "Sufficient resources found"}
	end

end

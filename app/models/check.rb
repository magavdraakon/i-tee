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
		info = %x(./utils/check-resources)
		if $?.exitstatus === 0
			{success: true, message: "Sufficient resources found"}
		else
			{success: false, message: 'Sorry, there are currently not enough resources to start the attempt. Please try again in a while.'}
		end
		{success: true, message: "Sufficient resources found"}
	end

end

class Check 
	

	# get free memory
	def self.get_memory

	end

	# get free disk
	def self.get_disk

	end

	# t/f has minimal memory and disk space to run average lab
	def self.has_free_resources
		info = %x(./utils/check-resources)
		return $?.exitstatus === 0
	end

end

class Check 
	

	# get free memory
	def self.get_memory

	end

	# get free disk
	def self.get_disk

	end

	# t/f has minimal memory and disk space to run average lab
	def self.has_free_resources
		# ask vboxmanager for resources
		result = Virtualbox.get_request('/resources.json', {}, true)
		if result['status'] === 200
			{success: true, message: "Sufficient resources found"}
		else
			{success: false, message: 'Sorry, there are currently not enough resources to start the attempt. Please try again in a while.'}
		end
	end

	def self.vboxmanager_status
		s = Time.now
		result = Virtualbox.get_request('/status.json', {}, true)
		diff = (Time.now - s)*1000 # to milliseconds
		result['diff'] = diff
		if result['status'] != 200
			raise result['data']
		end
		result
	end

	def self.guacamole_proxy_status
		{"versions": {"git": "TODO", "date": "N/A", "node":"N/A"}.stringify_keys, "diff": "N/A" }.stringify_keys
	end

	def self.platform_versions
		info = {ruby: "N/A", rails: "N/A", version:"N/A", commit: "N/A", date: "N/A"}
		ver = AppVersion::APP_VERSION.chomp.split(' ')
		ver.shift # dump "i-tee"
		info[:version] = ver.shift || "N/A"
		info[:commit] = ver.shift || "N/A"
		info[:date] = (ver.join(' ')!="" ? ver.join(' ') : "N/A" )
		itee = AppVersion::PLATFORM_INFO.split(', ')

		info[:ruby] = (itee.first && itee.first.include?('Ruby: ') ? itee.first.gsub('Ruby: ', '') : "N/A")
		info[:rails] = (itee.last && itee.last.include?('Rails: ') ? itee.last.gsub('Rails: ', '') : "N/A")
		vbox = {}
		begin
			vbox = Check.vboxmanager_status
			Rails.logger.debug vbox
		rescue Exception => e
			Rails.logger.error e
		end
		proxy = {}
		begin
			proxy = Check.guacamole_proxy_status
			Rails.logger.debug proxy
		rescue Exception => e
			Rails.logger.error e
		end
		{ itee: info, vboxmanager: vbox['versions'], vboxmanager_responce: vbox['diff'], guacamole: proxy['versions'], guacamole_responce: proxy['diff']}
	end

end

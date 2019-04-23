require "net/http"
require "uri"
require "json"

class Virtualbox < ActiveRecord::Base

	# used in visualization views
	def self.get_machines(state='', where={}, sort='')
		where = {} unless where
		case state
		when 'running'
			vms = Virtualbox.running_machines
		when 'stopped'
			vms = Virtualbox.stopped_machines
		when 'template'
			vms = Virtualbox.template_machines
		else
			vms = Virtualbox.all_machines
		end
		logger.debug "machines are: #{vms.join(', ')}"
		# filter names if needed
		if where.key?(:name) && where[:name] != ''
			vms = vms.select{|vm| vm.downcase.include?(where[:name].downcase)} # check if name is similar
		end
		return [] if vms.blank?
		# get vm_info for all the names
		infos = Virtualbox.vm_info(vms)
		vms_info = []
		infos.each do |vm|
			if vm.is_a?(Hash)
				info = Virtualbox.bind_info(vm)

				if where.key?(:lab) && where[:lab]!='' && (!info.key?('lab') || info['lab']['id'].to_i != where[:lab].to_i )# only for this lab
					next
				end
				if where.key?(:user) && where[:user] != '' &&  (!info.key?('user') || info['user']['id'].to_i != where[:user].to_i) # only for this user
					next
				end
				if where.key?(:group) && where[:group] != '' &&  !info['groups'].any? {|group| group.downcase.include? where[:group].downcase}
					next
				end
				if where.key?(:VRDEActiveConnection) && where[:VRDEActiveConnection] != 'any' && where[:VRDEActiveConnection] != info['VRDEActiveConnection']# check if connection is active
					next
				end
				vms_info << info
			else
				logger.warn vm
				next
			end
		end
		vms_info
	end

	# used in visualization view and system info (vm count)
	def self.running_machines
		Virtualbox.get_request('/vms/running.json', {}).map{ |v| v['name']}
	end

	def self.stopped_machines
		Virtualbox.get_request('/vms/stopped.json', {}).map{ |v| v['name']}
	end
	# used i user model (reset rdp pw), system info, vm start
	def self.all_machines
		Virtualbox.get_request('/vms/all.json', {}).map{ |v| v['name']}
	end

	def self.search_machines(vm)
		Virtualbox.get_request('/vms/search.json', {search: vm }).map{ |v| v['name']}
	end

	def self.template_machines
		Virtualbox.get_request('/vms/templates.json', {}).map{ |v| v['name']}
	end

	def self.vm_info(input)
		if input.is_a?(Array)
			Virtualbox.get_request('/vms/info.json', {names: input}).map{|v| v['data'] } # extract vm info hashes / error messages
		else
			Virtualbox.get_request('/vms/info.json', {name: input}) # request returns data
		end
	end

	def self.bind_info(vm)
		unless vm['groups'].blank?
			vmname = (vm['groups'][0] ? vm['groups'][0].gsub('/', '').strip : '' )# first group is machine name
			if vmname != ''
				vmt = LabVmt.where('name=?', vmname).first
				if vmt
					vm['lab'] = Lab.select('id, name').where("id=?", vmt.lab_id).first.as_json
				end
			end
			if vm['groups'].count>1  # second group is user name
				username =  vm['groups'][1].gsub('/', '').strip
				if username != ''
					user = User.select('id, username, name').where('username=?', username).first
					if user
						vm['user']=user.as_json
					end
				end
			end
		end
		vm
	end

	# called during vm start
	def self.set_port_range(vm, range='9000-11000', sync=false)
		logger.info "SET PORT RANGE CALLED: vm=#{vm} range=#{range}"
		result = Virtualbox.put_request('/vms/port.json', {name: vm, range: range, sync: sync})
		# result is either a success message or raises a error
		#ok = "VM '#{vm}' port range set to #{range}"
		#kok = "Unable to set running VM '#{vm}' port range to #{range}"
		logger.info "SET PORT RANGE END: #{result}"
		result
	end

	def self.start_vm(vm, sync=true)
		logger.info "VM START CALLED: vm=#{vm}"
		Virtualbox.set_port_range(vm) # set default port range of 9000-11000 
		result = Virtualbox.put_request('/vms/start.json', {name: vm, sync: sync})
		# result is either a success message or raises a error
		#ok = "VM '#{vm}' started"
		#kok = "VM '#{vm}' already started"
		logger.info "VM START END: #{result}"
		result
	end

	def self.stop_vm(vm, sync=false)
		logger.info "VM STOP CALLED: vm=#{vm}"
		result = Virtualbox.put_request('/vms/stop.json', {name: vm, sync: sync})
		# result is either a success message or raises a error
		#ok = "VM '#{vm}' stopped"
		logger.info "VM STOP END: #{result}"
		result
	end

	def self.pause_vm(vm, sync=false)
		logger.info "VM PAUSE CALLED: vm=#{vm}"
		result = Virtualbox.put_request('/vms/pause.json', {name: vm, sync: sync})
		# result is either a success message or raises a error
		#ok = "VM '#{vm}' paused"
		logger.info "VM PAUSE END: #{result}"
		result
	end

	def self.resume_vm(vm, sync=false)
		logger.info "VM RESUME CALLED: vm=#{vm}"
		result = Virtualbox.put_request('/vms/resume.json', {name: vm, sync: sync})
		# result is either a success message or raises a error
		#ok = "VM '#{vm}' started"
		#kok = "VM '#{vm}' already started"
		logger.info "VM RESUME END: #{result}"
		result
	end

	def self.delete_vm(vm, sync=false)
		logger.info "VM DELETE CALLED: vm=#{vm}"
		result = Virtualbox.delete_request('/vms/delete.json', {name: vm, sync: sync})
		# result is either a success message or raises a error
		#ok = "VM '#{vm}' deleted"
		#kok = "VM '#{vm}' already deleted"
		logger.info "VM DELETE END: #{result}"
		result
	end

	def self.clone(vm, name, snapshot = '', sync=false)
		logger.info "VM CLONE CALLED: snapshot=#{snapshot} vmt=#{vm} vm=#{name}"
		result = Virtualbox.post_request('/vms/clone.json', {template: vm, name: name, snapshot:snapshot, sync: sync})
		# result is either a success message or raises a error
		# ok = "VM #{name} cloned from '#{vm}'"
		logger.info "VM CLONE END: #{result}"
		result
	end

	def self.set_groups(vm, groups, sync=false)
		loginfo = "vm=#{vm} groups=#{groups.join(',')}"
		logger.info "SET GROUPS CALLED: #{loginfo}"
		result = Virtualbox.put_request('/vms/groups.json', {name: vm, groups:groups, sync: sync})
		# result is either a success message or raises a error
		# ok = "VM '#{vm}' groups set to #{groups.join(',')}"
		logger.info "SET GROUPS END: #{result}"
		result
	end

	def self.set_extra_data(vm, key, value = nil, sync=false)
		loginfo = "vm=#{vm} field=#{key} value=#{value}"
		logger.info "SET EXTRA DATA CALLED: #{loginfo}"
		result = Virtualbox.put_request('/vms/extradata.json', {name: vm, key:key, value:value, sync: sync})
		# result is either a success message or raises a error
		# ok = "VM '#{vm}' extradata #{key} set to #{value}" 
		logger.info "SET EXTRA DATA END: #{result}"
		result
	end

	
	def self.set_extra(vm, values=[], sync=false)
		loginfo = "vm=#{vm} values=#{values}"
		logger.info "SET EXTRA CALLED: #{loginfo}"
		begin
			result = Virtualbox.put_request('/vms/extradata.json', {name: vm, values:values, sync: sync})
			# result is either a success message or raises a error
			# ok = "VM '#{vm}' extradata #{key} set to #{value}" 
			# nok = "Failed to set VM '#{vm}' extradata #{key} to #{value}"
			logger.info "SET EXTRA END: #{result}"
			result
		rescue Exception => e
			# TODO: check the result and run the call again with fields that failed until no more failures?
			raise e.message
		end
	end

	def self.set_network(vm, slot, type, name='', sync=false)
		loginfo = "vm=#{vm} slot=#{slot} type=#{type} name=#{name}"
		logger.info "SET NETWORK CALLED: #{loginfo}"
		result = Virtualbox.put_request('/vms/set_network.json', {name: vm, slot:slot, type:type, nw_name:name, sync: sync})
		# result is either a success message or raises a error
		# ok = "VM '#{vm}' network slot #{slot} set to #{type} #{name}"
		logger.info "SET NETWORK END: #{result}"
		result
	end

	def self.set_running_network(vm, slot, type, name='', sync=false)
		loginfo = "vm=#{vm} slot=#{slot} type=#{type} name=#{name}"
		logger.info "SET RUNNING NETWORK CALLED: #{loginfo}"
		result = Virtualbox.put_request('/vms/set_running_network.json', {name: vm, slot:slot, type:type, nw_name:name, sync: sync})
		# result is either a success message or raises a error
		# ok = "VM '#{vm}' network slot #{slot} set to #{type} #{name}"
		logger.info "SET NETWORK END: #{result}"
		result
	end

	def self.reset_vm_rdp(vm, sync=false)
		logger.info "RESET RDP CALLED: vm=#{vm}"
		result = Virtualbox.put_request('/vms/reset_rdp.json', {name: vm, sync: sync})
		# result is either a success message or raises a error
		# ok = "RDP reset for VM '#{vm}'"
		logger.info "RESET RDP END: #{result}"
		result
	end
	# run guestcontrol sun --exe command as user
	def self.gc_run(vm, user='', pass='', cmd={}, sync=false)
		logger.info "GC RUN CALLED: vm=#{vm}"
		result = Virtualbox.put_request('/vms/gc/run.json', {name: vm, username:user, password:pass, cmd:cmd, sync: sync}, true)
		logger.info "GC RUN END: #{result}"
		result
	end


	def self.take_snapshot(vm, sync=false)
		logger.info "SNAPSHOT CALLED: vm=#{vm}"
		result = Virtualbox.post_request('/vms/snapshot.json', {name: vm, sync: sync})
		# result is either a success message or raises a error
		# ok = "Took snapshot #{name} of '#{vm}'"
		logger.info "SNAPSHOT END: #{result}"
		result
	end


	def self.set_drive(vm, controller, port, device, type, path, sync=false )
		logger.info "SET DRIVE CALLED: vm=#{vm}"
		result = Virtualbox.put_request('/vms/drive.json', {name: vm, controller: controller, port: port, device: device, type:type, path:path, sync: sync})
		# result is either a success message or raises a error
		logger.info "SET DRIVE END: #{result}"
		result
	end

	def self.set_drives(vm, drives, sync=false )
		logger.info "SET DRIVES CALLED: vm=#{vm}"
		result = Virtualbox.put_request('/vms/drive.json', {name: vm, drives:drives, sync: sync})
		# result is either a success message or raises a error
		logger.info "SET DRIVES END: #{result}"
		result
	end

  def self.unset_drive(vm, controller, port, device, sync=false )
  	logger.info "UNSET DRIVE CALLED: vm=#{vm}"
		result = Virtualbox.delete_request('/vms/drive.json', {name: vm, controller: controller, port: port, device: device, sync: sync})
		# result is either a success message or raises a error
		logger.info "UNSET DRIVE END: #{result}"
		result
  end

  def self.unset_drives(vm, drives, sync=false )
  	logger.info "UNSET DRIVE CALLED: vm=#{vm}"
		result = Virtualbox.delete_request('/vms/drive.json', {name: vm, drives:drives, sync: sync})
		# result is either a success message or raises a error
		logger.info "UNSET DRIVE END: #{result}"
		result
  end

	### HTTP

	def self.get_request(path, params, all=false)
		Virtualbox.request_json :get, path, params, all
	end

	def self.post_request(path, params, all=false)
		Virtualbox.request_json :post, path, params, all
	end

	def self.put_request(path, params, all=false)
		Virtualbox.request_json :put, path, params, all
	end

	def self.delete_request(path, params, all=false)
		Virtualbox.request_json :delete, path, params, all
	end

	# manage the result, raise error when request not HTTP OK
	def self.request_json(method, path, params, all=false)
		response = Virtualbox.request(method, path, params)
		# check response code
		body = JSON.parse(response.body)
		if response.is_a?(Net::HTTPSuccess)
			return body if all
			return body['data'] if body.is_a?(Hash) # data contains result
			return body if body.is_a?(Array) # public methods (vm lists) return arrays
		else # some other http return code
			logger.warn "REQUEST ERROR"
			logger.warn response.body
			return body if all && body
			raise body['data'] # data contains error message
		end
		rescue JSON::ParserError
			response
	end
	# make the request, manage retries/no connection errors
	def self.request(method, path, params = {}, retries = 3)
		raise "Vbox host not specified" unless Rails.configuration.vbox
		logger.info "VBOX REQUEST CALLED: method=#{method} path=#{path} params=#{params} retries_left=#{retries}/3"
		uri = URI.parse( Rails.configuration.vbox['host'] )
		params['apiKey'] = Rails.configuration.vbox['token']
		http = Net::HTTP.new(uri.host, uri.port)
		http.read_timeout = 500 # seconds
		if uri.scheme == 'https'
			http.use_ssl = true
			if Rails.env == 'development'
				http.verify_mode = OpenSSL::SSL::VERIFY_NONE # TODO: IMPORTANT!! read into this
			end
		end
		verbs = {
			:get => Net::HTTP::Get,
			:post => Net::HTTP::Post,
			:put => Net::HTTP::Put,
			:delete => Net::HTTP::Delete
		}
		request = verbs[method.to_sym].new(path, { 'Content-Type' => 'application/json' })
		request.body = params.to_json
		result = http.request(request)
		logger.debug "VBOX REQUEST RESULT: #{result} #{result.body}"
		return result
		rescue Net::ReadTimeout
	    # try again until no more timeout? max attempts?
	    if retries > 0
	      logger.error "HOST timeout: #{Rails.configuration.vbox['host']} - trying again"
	      return Virtualbox.request(method, path, params, (retries -1) )
	    else
	      logger.error "HOST timeout: #{Rails.configuration.vbox['host']} - all retries used up"
	      raise "Host timed out, no more retries left"
	    end
		rescue Errno::ENOENT
			logger.error "HOST ENOENT: error #{Rails.configuration.vbox['host']}"
			raise "VboxManager not found" #false if can't find the server
		rescue Errno::ECONNREFUSED
			logger.error "HOST ECONNREFUSED: error #{Rails.configuration.vbox['host']}"
			raise "Connection to VboxManager denied" # connection refused
		rescue Exception => e
			logger.error "HOST Exception: #{Rails.configuration.vbox['host']} - #{e}"
			raise "Unknown error while connecting to VboxManager"
	end


# set global admin credentials to machines, 
	# only set admin for machines not in db if only_others is true to save time as machine start sets the global admin already
	# 
	def self.set_admin(only_others=false)
		logger.info "SET ADMIN CALLED"
		username = Rails.configuration.guacamole2["username"]
		password = Rails.configuration.guacamole2["password"]
		raise "No username or password given, check the configuration!" unless username && password

		hash = Digest::SHA256.hexdigest(password)
    Virtualbox.all_machines.each do |vm|
      begin
      	if only_others && Vm.where(name: vm).first
      		logger.debug "SET ADMIN: skipping #{vm} as it is in database and probably has the password already"
      		next
      	end
        Virtualbox.set_extra_data(vm, "VBoxAuthSimple/users/#{username}", hash);
        logger.debug "SET ADMIN: successfully set global admin for #{vm}"
      rescue Exception => e
        logger.error "SET ADMIN: Failed to set RDP password for machine #{vm}: #{e.message}"
      end
    end
    logger.info "SET ADMIN END"
	end

	# get token for machine by name
	def self.open_rdp(vm, user, readonly=false)
		machine = Virtualbox.vm_info(vm)
		if user.is_admin?
			return Virtualbox.guacamole_token(machine['vrdeport'].to_i, nil, nil, readonly)
		else
			raise 'Permission denied'
		end
	end

	# generate guacamole token based on port, username and password
	def self.guacamole_token(port, username=nil, password=nil, readonly=false)
		username = Rails.configuration.guacamole2["username"] unless username
		password = Rails.configuration.guacamole2["password"] unless password
		raise "No username or password given" unless username && password
		data = {
      "connection": {
        "type": "rdp", 
        "settings": { 
          "hostname": Rails.configuration.guacamole2["guacd_host"], 
          "username": username, 
          "password": password, 
          "port": port, 
          "clipboard-encoding": "UTF-8",
          "color-depth":16
        } 
      } 
    }
    unless readonly
      data[:connection][:settings][:"resize-method"] = "display-update"
    else
      data[:connection][:settings][:"read-only"] = true
    end
    iv = SecureRandom.random_bytes(16)
    cipher = OpenSSL::Cipher.new('AES-256-CBC')
    cipher.encrypt  # set cipher to be encryption mode
    cipher.key = Rails.configuration.guacamole2["cipher_password"]
    cipher.iv  = iv
    encrypted = ''
    encrypted << cipher.update(data.to_json)
    encrypted << cipher.final
    value = {
      iv:  Base64.encode64(iv),
      value: Base64.encode64(encrypted)
    }
    token = Base64.encode64(value.to_json).gsub(/\n/, '')
    token
	end



 #### OLD METHODS some are still needed afterwards

# this is a class to activate different command-line vboxmanage commands and translate the results for the rails app

	@@vm_mutex = Mutex.new

	def self.vboxmanage(cmnd, sync=true) # if vm_mutex is not false use syncronize
		stdout = ''
		if @@vm_mutex && sync
			@@vm_mutex.synchronize do
				stdout = %x(utils/vboxmanage #{cmnd} )
			end
		else
			stdout = %x(utils/vboxmanage #{cmnd})
		end
		status = $?.exitstatus
		return {stdout: stdout, exitstatus: status }
	end

	def self.get_vm_info(name, static=false, try_again=true)
		logger.debug "GET VM INFO CALLED: vm=#{name} "
		retry_sleep = 1 # seconds to wait before retry
		result = false
		if try_again
			(0..5).each do |try|
				logger.debug "GET VM INFO: try=#{try}/5 vm=#{name}"
				result = Virtualbox.vboxmanage("showvminfo #{Shellwords.escape(name)} --machinereadable 2>&1", true)
				if result[:exitstatus] != 0
					logger.debug "GET VM INFO: failed try=#{try}/5 vm=#{name}\n#{result[:stdout]}"
					if try < 5
						sleep retry_sleep
						next  # go to next loop if not last
					else # last attempt failed, error depends on output
						if result[:stdout].start_with? "VBoxManage: error: Could not find a registered machine named '#{name}'"
							logger.warn "GET VM INFO FAILED: no such machine try=#{try}/5 vm=#{name}"
							raise 'Not found'
						else
							logger.error "GET VM INFO FAILED: try=#{try}/5 vm=#{name}"
							raise "Failed to get vm info try=#{try}/5"
						end
					end
				else
					logger.debug "GET VM INFO SUCCESS: try=#{try}/5 vm=#{name}"
					break # exit loop
				end
			end # eof loop
		else
			# for views for faster loading!
			result = Virtualbox.vboxmanage("showvminfo #{Shellwords.escape(name)} --machinereadable 2>&1", true)
			if result[:exitstatus] != 0
				logger.debug "GET VM INFO: failed vm=#{name}\n#{result[:stdout]}"
				if result[:stdout].start_with? "VBoxManage: error: Could not find a registered machine named '#{name}'"
					logger.warn "GET VM INFO FAILED: no such machine vm=#{name}"
					raise 'Not found'
				else
					logger.error "GET VM INFO FAILED: vm=#{name}"
					raise 'Failed to get vm info'
				end
			end
		end
		vm = {}
		if result 
			result[:stdout].split(/\n+/).each do |row|
				if row.strip!=''
					f=row.split('=')
					value=f.last.gsub('"', '').gsub('<not set>', '')
					field=f.first.gsub('"', '')
						

					if field.include? '['
						subfield = field.slice(field.index('[')..field.index(']'))
						field.gsub!(subfield,'')
						subfield.gsub!('[','').gsub!( ']','')

						if subfield.include? '/'
							s=subfield.split('/')
							subsub = s.last
							subfield=s.first
						end
					end

					if subfield
						unless vm[field] # create empty hash to house the subfield
							vm[field] = {}
						end
						if subsub
							unless vm[field][subfield] # create empty hash to house the sub-subfield
								vm[field][subfield]={}
							end
							vm[field][subfield][subsub] = value
						else
							vm[field][subfield] = value
						end
					else
						vm[field] = value
					end
				end
			end
			# field-specific parsing
			if vm['groups']
				vm['groups'] = vm['groups'].split(',')
				unless static
					vmname = vm['groups'][0] ? vm['groups'][0].gsub('/', '').strip : '' # first group is machine name
					if vmname != ''
						vmt = LabVmt.where('name=?', vmname).first
						if vmt
							vm['lab']=Lab.select('id, name').where("id=?", vmt.lab_id).first.as_json
						end
					end
					username = vm['groups'][1] ? vm['groups'][1].gsub('/', '').strip : '' # second group is user name
					if username != ''
						user = User.select('id, username, name').where('username=?', username).first
						if user
							vm['user']=user.as_json
						end
					end
				end
			end
			if vm['CurrentSnapshotNode']
				value = vm[vm['CurrentSnapshotNode'].gsub('Name', 'Description')]
				begin
					value.to_time
				rescue
					value= ''
				end
				vm['CurrentSnapshotDescription']=value
			end
		end # eof if result
		vm
	end

	# connection information
	def self.remote(typ, port, username=nil, password=nil)
		username = Rails.configuration.guacamole2["username"] unless username
		password = Rails.configuration.guacamole2["password"] unless password
		raise "No username or password given" unless username && password

		begin
			rdp_host = ITee::Application.config.rdp_host
		rescue
			rdp_host=`hostname -f`.strip
		end

		case typ
			when 'win'
				desc = "cmdkey /generic:#{rdp_host} /user:localhost&#92;#{username} /pass:#{password}&amp;&amp;"
				desc += "mstsc.exe /v:#{rdp_host}:#{port} /f"
			when 'rdesktop'
				desc ="rdesktop  -u#{username} -p#{password} -N -a16 #{rdp_host}:#{port}"
			when 'xfreerdp'
				desc ="xfreerdp  --plugin cliprdr -g 90% -u #{username} -p #{password} #{rdp_host}:#{port}"
			when 'mac'
				desc ="open rdp://#{username}:#{password}@#{rdp_host}:#{port}"
			else
				desc ="rdesktop  -u#{username} -p#{password} -N -a16 #{rdp_host}:#{port}"
		end

	end

	def self.open_guacamole(vm, user, admin=false)
		add = ( admin ? '-admin' : '')
		if user.rdp_password==""
			#TODO! no rdp password - create it? 
			return {success: false, message: 'Please generate a rdp password'} 
		end
		machine =  Virtualbox.vm_info(vm)
		# check if vm has guacamole enabled
		if machine['VMState']=='running'

				rdp_port =  machine['vrdeport'].to_i

				user_prefix = ITee::Application.config.guacamole[:user_prefix]
				max_connections = ITee::Application::config.guacamole[:max_connections]
				max_user_connections = ITee::Application::config.guacamole[:max_connections_per_user]
				url_prefix = ITee::Application::config.guacamole[:url_prefix]
				begin
					rdp_host = ITee::Application::config.guacamole[:rdp_host]
				rescue
					logger.warn "RDP host for Guacamole not specified"
					rdp_host = ITee::Application::config.rdp_host
				end
				cookie_domain = ITee::Application::config.guacamole[:cookie_domain]

				g_username = user_prefix+user.username+add
				g_password = user.rdp_password
				g_name = user_prefix+vm
				# check if the user has a guacamole user
				g_user = GuacamoleUser.where(username: g_username ).first
				unless g_user
					# create user
					g_user = GuacamoleUser.create({username: g_username, password_hash:  g_password, timezone: 'Etc/GMT+0'})
					unless g_user
						logger.debug g_user
						return {success: false, message: 'unable to add user to guacamole'} 
					end
				else
					# update password just in case
					g_user.password_hash = user.rdp_password
					g_user.apply_salt
					g_user.save
				end 
				params = [
					{ parameter_name: 'hostname', parameter_value: rdp_host },
					{ parameter_name: 'port', parameter_value: rdp_port },
					{ parameter_name: 'username', parameter_value: user.username+add },
					{ parameter_name: 'password', parameter_value: g_password },
				# { parameter_name: 'color-depth', parameter_value: 255 }
				]
				# check if there is a connection
				g_conn = GuacamoleConnection.where(connection_name: g_name ).first
				unless g_conn # find by full name
					# create connection
					# data format {connection_name, protocol, max_connections, max_connections_per_user, params {hostname, port, username, password, color-depth}
					g_conn = GuacamoleConnection.create( connection_name: g_name, 
						protocol: 'rdp' , 
						max_connections: max_connections, 
						max_connections_per_user: max_user_connections )
				 
					if g_conn
						g_conn.add_parameters(params)
					else
						logger.debug g_conn
						return {success: false, message: 'unable to create connection in guacamole'} 
					end
				else # connection existed
					# update/create all parameters
					params.each do |p|
						# find parameter 
						param = GuacamoleConnectionParameter.where(connection_id: g_conn.connection_id, parameter_name: p[:parameter_name]).first
						if param #update
							GuacamoleConnectionParameter.where(connection_id: g_conn.connection_id, parameter_name: p[:parameter_name]).limit(1).update_all(parameter_value: p[:parameter_value])
						else # create
							GuacamoleConnectionParameter.create(connection_id: g_conn.connection_id, parameter_name: p[:parameter_name], parameter_value: p[:parameter_value] )
						end
					end          
				end #EOF connection check
				# check if the connection persist/has been created
				if g_conn
					# allow connection if none exists
					permission = GuacamoleConnectionPermission.where(user_id: g_user.user_id, connection_id: g_conn.connection_id,permission: 'READ').first
					unless permission # if no permission, create one
						result = GuacamoleConnectionPermission.create(user_id: g_user.user_id, connection_id: g_conn.connection_id, permission: 'READ')
						unless result
							return {success: false, message: 'unable to allow connection in guacamole'} 
						end
					end
					# log in 
					post = HttpRequest.post(url_prefix + "/api/tokens", {username: g_username, password: g_password})
					if post.body && post.body['authToken']
						# get machine url
						uri = GuacamoleConnection.get_url(g_conn.connection_id)
						path = url_prefix + "/#/client/#{uri}"
						{ success: true, url: path, token: post.body, domain: cookie_domain}
					else
						{success: false, message: 'unable to log in'}
					end
				else
					{ success: false, message: 'unable to get machine connection'}
				end
		else
			{success: false, message: 'please start this virtual machine before trying to establish a connection'}
		end
	end




	# NOT IN USE?
	def self.state(vm)
		stdout = ''
		@@vm_mutex.synchronize do
			stdout = %x(utils/vboxmanage showvminfo #{Shellwords.escape(vm)} 2>/dev/null | grep -E '^State:')
		end
		state = "#{stdout}".split(' ')[1]

		if $?.exitstatus != 0
			# Macine probably simply does not exist
			# TODO: check existence of machine
			return 'stopped'
		end

		case state
		when 'running'
			return 'running'
		when 'paused'
			return 'paused'
		when 'powered'
			return 'stopped'
		else
			logger.error "Invalid state: #{state}"
			raise "Invalid state"
		end
	end

 def self.scancodes
	codes = {}
	range = ('a'..'f').to_a
	codes['esc']=['1', '81']
	# 1 - 8
	(1...9).each do |i|
		codes["#{i}"]=["0#{i+1}", "8#{i+1}"]
	end
	['!','@','pound','$','%','^', '&', '*'].each_with_index do |v, i|
		codes["#{v}"] = ["2a 0#{i+2}", "8#{i+2} aa"]
	end
	['9', '0', '-', '=', 'bksp', 'tab'].each_with_index do |v, i|
		codes["#{v}"] = ["0#{range[i]}", "8#{range[i]}"]
	end
	['(', ')', '_', '+'].each_with_index do |v, i|
		codes["#{v}"] = ["2a 0#{range[i]}", "8#{range[i]} aa"]
	end
	['q','w','e','r','t','y','u','i','o','p'].each_with_index do |v, i|
		codes["#{v}"] = ["1#{i}", "9#{i}"]
		codes["#{v}".upcase] = ["2a 1#{i}", "9#{i} aa"] # shift down before pushing letter and releasing after letter is released
	end
	['[', ']', 'enter', 'ctrl', 'a', 's'].each_with_index do |v, i|
		codes["#{v}"] = ["1#{range[i]}", "9#{range[i]}"]
	end
	codes['{']=['2a 1a', '9a aa']
	codes['}']=['2a 1b', '9b aa']
	codes['A']=['2a 1e', '9e aa']
	codes['S']=['2a 1f', '9f aa']
	['d','f','g','h','j','k','l',';',"apostrophe",'tick'].each_with_index do |v, i|
		codes["#{v}"] = ["2#{i}", "a#{i}"]
		codes["#{v.upcase}"] = ["2a 2#{i}", "a#{i} aa"] unless [';',"'",'`'].include?(v)
	end
	codes[':']=['2a 27', 'a7 aa']
	codes['quote']=['2a 28', 'a8 aa']
	codes['~']=['2a 29', 'a9 aa']
	# TODO \ is special 
	['shift','backspace','z','x','c','v'].each_with_index do |v, i|
		codes["#{v}"] = ["2#{range[i]}", "a#{range[i]}"]
		codes["#{v.upcase}"] = ["2a 2#{range[i]}", "a#{range[i]} aa"] unless ['lshift','\\'].include?(v)
	end
	codes['|']=['2a 2b', 'ab aa']
	# TODO  prtsc is special. 
	['b','n','m',',','.','/','rshift','prtsc',"alt",'space'].each_with_index do |v, i|
		codes["#{v}"] = ["3#{i}", "b#{i}"]
		codes["#{v.upcase}"] = ["2a 3#{i}", "b#{i} aa"] if ['b','n','m'].include?(v)
	end
	codes['<']=['2a 33', 'b3 aa']
	codes['>']=['2a 34', 'b4 aa']
	codes['?']=['2a 35', 'b5 aa']
	['caps','f1','f2','f3','f4','f5'].each_with_index do |v, i|
		codes["#{v}"] = ["3#{range[i]}", "b#{range[i]}"]
	end
	['f6','f7','f8','f9','f10','num','scrl'].each_with_index do |v, i|
		codes["#{v}"] = ["4#{i}", "c#{i}"]
	end
	codes['f11']=['57','d7']
	codes['f12']=['58','d8']
	codes['ins']=['e0 52','e0 d2']
	codes['del']=['e0 53','e0 d3']
	codes['home']=['e0 47','e0 c7']
	codes['end']=['e0 4f','e0 cf']
	codes['pgup']=['e0 49','e0 c9']
	codes['pgdn']=['e0 51','e0 d1']
	codes['left']=['e0 4b','e0 cb']
	codes['right']=['e0 4d','e0 cd']
	codes['up']=['e0 48','e0 c8']
	codes['down']=['e0 50','e0 d0']
	codes['ralt']=['e0 38','e0 b8']
	codes['rctrl']=['e0 1d','e0 9d']
	codes['windows']=['e0 5b', 'e0 db']
	
	codes
 end

 # convert text to scancode sequence and send to machine
 def self.send_text(vm, text)
	begin
		codes = Virtualbox.scancodes
		# split rows
		lines = text.lines
		lines << '' if text.end_with?("\n") # make sure to keep the enter when it is supplied
		logger.debug "sent #{lines.count} lines"
		lines.each_with_index do |row, index|
			row.scan(/.{1,4}/).each do |chunk| # max 4 characters at a time
				input = []
				keys = chunk.split('')
				keys.each do |l|
					l = 'space' if l==' '
					l = 'quote' if l=='"'
					l = 'apostrophe' if l=="'"
					l = 'tick' if l=='`'
					l = 'backspace' if l=='\\' || l.ord == 92
					l = 'pound' if l=='#'
					raise "unknown key #{l}" unless codes[l]
					input << codes[l].join(' ')
				end
				result = Virtualbox.vboxmanage("controlvm #{Shellwords.escape(vm)} keyboardputscancode #{input.join(' ')} 2>&1", true)
				if result[:exitstatus] != 0
					raise 'Failed to send text to vm'
				end
				sleep 0.2
			end
			# put line return if there are more rows after this one
			if lines[index+1]
				result = Virtualbox.vboxmanage("controlvm #{Shellwords.escape(vm)} keyboardputscancode #{codes['enter'].join(' ')} 2>&1", true)
				if result[:exitstatus] != 0
					raise 'Failed to send enter to vm'
				end
				sleep 0.2
			end
		end
		{success: true, message: "Text successfully sent"}
	rescue Exception => e 
		logger.error e.to_s
		return {success: false, message: e.message || 'unexpected error while sending text' }
	end
 end

 # send key combo where keys are held down and released together "ctrl+alt+del"
 def self.send_keys(vm, pattern)
	begin
		codes = Virtualbox.scancodes
		keys = pattern.split('+').map { |v| v.strip.downcase }
		input = []
		# press down
		keys.each do |l|
			raise "unknown key #{l}" unless codes[l]
			input << codes[l][0]
		end
		logger.info "keyboardputscancode #{input.join(' ')}"
		result = Virtualbox.vboxmanage("controlvm #{Shellwords.escape(vm)} keyboardputscancode #{input.join(' ')} 2>&1", true)
		if result[:exitstatus] != 0
			raise 'Failed to send keys to vm'
		end
		sleep 0.2
		input = []
		#release
		keys.each do |l|
			raise "unknown key #{l}" unless codes[l]
			input << codes[l][1]
		end
		logger.info "keyboardputscancode #{input.join(' ')}"
		result = Virtualbox.vboxmanage("controlvm #{Shellwords.escape(vm)} keyboardputscancode #{input.join(' ')} 2>&1", true)
		if result[:exitstatus] != 0
			raise 'Failed to send keys to vm'
		end
		{success: true, message: "Keys successfully sent"}
	rescue Exception => e 
		logger.error e.to_s
		return {success: false, message: e.message || 'unexpected error while sending keys' }
	end
 end


end

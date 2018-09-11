class Virtualbox < ActiveRecord::Base

# this is a class to activate different command-line vboxmanage commands and translate the results for the rails app

	@@vm_mutex = Mutex.new

def self.get_machines(state='', where={}, sort='')
	unless where
		where={}
	end
	case state
		when 'running'
			vms = Virtualbox.running_machines
		when 'paused'
			vms = Virtualbox.paused_machines
		when 'stopped'
			vms = Virtualbox.stopped_machines
		when 'template'
			vms = Virtualbox.template_machines
		else
			vms = Virtualbox.all_machines
	end

	vms_info=[]
	vms.each do |vm|
		if where.key?(:name) and where[:name] != '' and !vm.downcase.include? where[:name].downcase # check if name is similar
			return
		end
		begin
			info = Virtualbox.get_vm_info(vm)  # get detiled info
		rescue
			# Ignore error, callee logs the error message
			return
		end
		if where.key?(:lab) and where[:lab] != '' and info['lab']['id'].to_i != where[:lab].to_i # only for this lab
			next
		end
		if where.key?(:user) and where[:user] != '' and info['user']['id'].to_i != where[:user].to_i # only for this user
			next
		end
		if where.key?(:group) and where[:group] != '' and  !info['groups'].any? {|group| group.downcase.include? where[:group].downcase}
			next
		end
		if where.key?(:VRDEActiveConnection) and where[:VRDEActiveConnection] != 'any' and where[:VRDEActiveConnection] != info['VRDEActiveConnection']# check if connection is active
			next
		end
		vms_info << info
	end
	vms_info
end

def self.running_machines
	info = %x(utils/vboxmanage list runningvms | cut -f2 -d'"')
	status= $?
	#logger.debug info
	if status.exitstatus===0
		info.split(/\n+/)
	else
		false
	end
end

def self.stopped_machines
	all = Virtualbox.all_machines
	running = Virtualbox.running_machines

	all - running
end

def self.all_machines
	info = %x(utils/vboxmanage list vms | cut -f2 -d'"')
	status = $?
	#logger.debug info
	if status.exitstatus===0
		info.split(/\n+/)
	else
		false
	end
end

def self.template_machines
	info = %x(utils/vboxmanage list vms | grep template | cut -f2 -d'"')
	status= $?
	#logger.debug info
	if status.exitstatus===0
		info.split(/\n+/)
	else
		false
	end
end

def self.get_vm_info(name, static=false)
	logger.debug "VIRTUALBOX. get vm info '#{name}'"
	stdout = %x(utils/vboxmanage showvminfo #{Shellwords.escape(name)} --machinereadable 2>&1)
	unless $?.exitstatus == 0
		if stdout.start_with? "VBoxManage: error: Could not find a registered machine named '#{name}'"
			raise 'Not found'
		end
		logger.error "Failed to get vm info: #{stdout}"
		raise 'Failed to get vm info'
	end

	vm = {}
	stdout.split(/\n+/).each do |row|
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

	vm
end

def self.get_all_rdp(user, port)
    [
      {os: ['Windows'], program: '', rdpline: Virtualbox.remote('win', port, user) },
      {os: ['Linux', 'UNIX'], program: 'xfreerdp', rdpline: Virtualbox.remote('xfreerdp', port, user) },
      {os: ['Linux', 'UNIX'], program: 'rdesktop', rdpline: Virtualbox.remote('rdesktop', port, user) },
      {os: ['MacOS'], program: '', rdpline: Virtualbox.remote('mac', port, user) }
    ]
  end
  # connection informations
  def self.remote(typ, port, user, admin=false)
    add = ( admin ? '-admin' : '')
    begin
      rdp_host=ITee::Application.config.rdp_host
    rescue
      rdp_host=`hostname -f`.strip
    end

    case typ
      when 'win'
        desc = "cmdkey /generic:#{rdp_host} /user:localhost&#92;#{user.username}#{add} /pass:#{user.rdp_password}&amp;&amp;"
        desc += "mstsc.exe /v:#{rdp_host}:#{port} /f"
      when 'rdesktop'
        desc ="rdesktop  -u#{user.username}#{add} -p#{user.rdp_password} -N -a16 #{rdp_host}:#{port}"
      when 'xfreerdp'
        desc ="xfreerdp  --plugin cliprdr -g 90% -u #{user.username}#{add} -p #{user.rdp_password} #{rdp_host}:#{port}"
      when 'mac'
        desc ="open rdp://#{user.username}#{add}:#{user.rdp_password}@#{rdp_host}:#{port}"
      else
        desc ="rdesktop  -u#{user.username}#{add} -p#{user.rdp_password} -N -a16 #{rdp_host}:#{port}"
    end

  end

def self.open_guacamole(vm, user, admin=false)
	add = ( admin ? '-admin' : '')
	if user.rdp_password==""
		#TODO! no rdp password - create it? 
		return {success: false, message: 'Please generate a rdp password'} 
	end
	machine =  Virtualbox.get_vm_info(vm, true)
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
#             { parameter_name: 'color-depth', parameter_value: 255 }
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

	def self.set_port_range(vm, range='9000-11000')
		logger.info "SET PORT RANGE CALLED: vm=#{vm} range=#{range}"
		retry_sleep = 1 # seconds to wait before retry
		(0..5).each do |try|
			logger.debug "SET PORT RANGE: try=#{try}/5 vm=#{vm} range=#{range}"
			@@vm_mutex.synchronize do
				stdout = %x(utils/vboxmanage modifyvm #{Shellwords.escape(vm)} --vrdeport #{Shellwords.escape(range)}  2>&1)
			end
			if $?.exitstatus != 0
				if stdout.start_with? "VBoxManage: error: The machine '#{vm}' is already locked by a session (or being locked or unlocked)"
					# machine is running
					logger.info "SET PORT RANGE: can not set port range for running vm try=#{try}/5 vm=#{vm}"
					return true # exit with true although port range was not changed?
				else
					logger.warn "SET PORT RANGE: failed try=#{try}/5 vm=#{vm} range=#{range} \n#{stdout}"
					if try < 5
						sleep retry_sleep
						next  # go to next loop if not last
					else # last attempt failed
						raise "Failed to set vm port range try=#{try}/5 range=#{range}"
					end
				end
			else # success 
				logger.info "SET PORT RANGE SUCCESS: try=#{try}/5 vm=#{vm}"
				return true
			end
		end # end loop

	end

 def self.state(vm)
	stdout = %x(utils/vboxmanage showvminfo #{Shellwords.escape(vm)} 2>/dev/null | grep -E '^State:')
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

	def self.start_vm(vm)
		logger.info "VM START CALLED: vm=#{vm}"
		Virtualbox.set_port_range(vm) # set default port range of 9000-11000 
		retry_sleep = 2 # seconds to wait before retry
		(0..5).each do |try|
			logger.debug "VM START: try=#{try}/5 vm=#{vm}"
			@@vm_mutex.synchronize do
				stdout = %x(utils/vboxmanage startvm #{Shellwords.escape(vm)} --type headless  2>&1)
			end
			if $?.exitstatus != 0
				if stdout.start_with? "VBoxManage: error: The machine '#{vm}' is already locked by a session (or being locked or unlocked)"
					logger.info "VM START SUCCESS: already started try=#{try}/5 vm=#{vm}"
					return true # exit if successful
				else
					logger.warn "VM START: failed try=#{try}/5 vm=#{vm} \n#{stdout}"
					if try < 5
						sleep retry_sleep
						next  # go to next loop if not last
					else # last attempt failed
						raise "Failed to start vm try=#{try}/5"
					end
				end
			else
				logger.info "VM START SUCCESS: try=#{try}/5 vm=#{vm}"
				return true # exit if successful
			end
		end # eof loop
	end

	def self.stop_vm(vm)
		logger.info "VM STOP CALLED: vm=#{vm}"
		retry_sleep = 2 # seconds to wait before retry
		(0..5).each do |try|
			logger.debug "VM STOP: try=#{try}/5 vm=#{vm}"
			stdout = %x(utils/vboxmanage controlvm #{Shellwords.escape(vm)} poweroff 2>&1)
			if $?.exitstatus != 0
				if stdout.start_with? "VBoxManage: error: Machine '#{vm}' is not currently running" 
					logger.info "VM STOP SUCCESS: already stopped try=#{try}/5 vm=#{vm}"
					return true # exit if successful
				else
					logger.warn "VM STOP: failed try=#{try}/5 vm=#{vm} \n#{stdout}"
					if try < 5
						sleep retry_sleep
						next  # go to next loop if not last
					else # last attempt failed
						raise "Failed to stop vm try=#{try}/5"
					end
				end
			else # success status
				logger.info "VM STOP SUCCESS: try=#{try}/5 vm=#{vm}"
				return true # exit if successful
			end
		end # eof loop
	end

 def self.pause_vm(vm)
	stdout = %x(utils/vboxmanage controlvm #{Shellwords.escape(vm)} savestate 2>&1)
	if $?.exitstatus != 0
		logger.error "Failed to pause vm: #{stdout}"
		raise 'Failed to pause vm'
	end
 end

 def self.resume_vm(vm)
	stdout = %x(utils/vboxmanage controlvm #{Shellwords.escape(vm)} resume 2>&1)
	if $?.exitstatus != 0
		logger.error "Failed to resume vm: #{stdout}"
		raise 'Failed to resume vm'
	end
 end

	def self.delete_vm(vm)
		logger.info "VM DELETE CALLED: vm=#{vm}"
		retry_sleep = 2 # seconds to wait before retry
	 	(0..5).each do |try|
			logger.debug "VM DELETE: try=#{try}/5 vm=#{vm}"
			stdout = %x(utils/vboxmanage unregistervm #{Shellwords.escape(vm)} --delete 2>&1)
			if $?.exitstatus != 0
				logger.warn "VM DELETE: failed try=#{try}/5 vm=#{vm} \n#{stdout}"
				if try < 5
					sleep retry_sleep
					next  # go to next loop if not last
				else # last attempt failed
					raise "Failed to delete vm try=#{try}/5"
				end
			else # success
				logger.info "VM DELETE SUCCESS: try=#{try}/5 vm=#{vm}"
				return true # exit if successful
			end
		end
 end

	def self.clone(vm, name, snapshot = '')
		logger.info "VM CLONE CALLED: snapshot=#{snapshot} vmt=#{vm} vm=#{name}"
		begin 
			# if snapshot is not defined look for latest
			if snapshot.blank? && !(snapshot === false) # do not get latest snapshot if specifically said to not use a snapshot
				template = Virtualbox.get_vm_info(vm)
				snapshot = template['CurrentSnapshotName']
			end
			retry_sleep = 3 # seconds to wait before retry cloning
			if !snapshot.blank? # only if snapshot set
				loginfo = "snapshot=#{snapshot} vmt=#{vm} vm=#{name}"
				(0..5).each do |try|
					logger.debug "VM CLONE: Cloning from snapshot try=#{try}/5 #{loginfo}"
					stdout = %x(utils/vboxmanage clonevm #{Shellwords.escape(vm)} --snapshot #{Shellwords.escape(snapshot)} --options link --name #{Shellwords.escape(name)} --register 2>&1)
					if $?.exitstatus != 0
						logger.warn "VM CLONE: Failed to clone vm try=#{try}/5 #{loginfo} \n#{stdout}"
						if try < 5
							sleep retry_sleep
							next  # go to next loop if not last
						end
					else # success!
						logger.info "VM CLONE SUCCESS: Cloned from snapshot try=#{try}/5 #{loginfo}"
						return true # exit cloning if successful
					end
				end # eof loop
			end # eof if snapshot
			# we will reach here if cloning fails above or no snapshot is found, try to clone directly from machine instead
			loginfo = "vmt=#{vm} vm=#{name}"
			(0..5).each do |try|
				logger.debug "VM CLONE: Cloning from template try=#{try}/5 #{loginfo}"
				stdout = %x(utils/vboxmanage clonevm #{Shellwords.escape(vm)} --name #{Shellwords.escape(name)} --register 2>&1)
				if $?.exitstatus != 0
					logger.warn "VM CLONE: Failed to clone vm try=#{try}/5 #{loginfo} \n#{stdout}"
					if try < 5
						sleep retry_sleep
						next  # go to next loop if not last
					end
					# last loop
					raise "Failed to clone vm from template try=#{try}/5 vmt=#{vm}" # will be raised to caller
				else # success!
					logger.info "VM CLONE SUCCESS: Cloned from template try=#{try}/5 #{loginfo}"
					return true # exit cloning if successful
				end
			end # eof loop
		rescue Exception => e
			logger.error e
			if e.message == 'Not found'
				raise "Template machine not found vmt=#{vm}"
			else
				raise e.message
			end
		end
	end

 def self.set_groups(vm, groups)
 	loginfo = "vm=#{vm} groups=#{groups.join(',')}"
	logger.debug "SET GROUPS CALLED: #{loginfo}"
	retry_sleep = 1
	(0..5).each do |try|
		stdout = %x(utils/vboxmanage modifyvm #{Shellwords.escape(vm)} --groups #{Shellwords.escape(groups.join(','))} 2>&1)
		if $?.exitstatus != 0
			logger.warn "SET GROUPS: failed try=#{try} #{loginfo}\n #{stdout}"
			if try < 5
				sleep retry_sleep
				next  # go to next loop if not last
			else # last attempt failed
				raise "Failed to set vm groups try=#{try}/5 groups=#{groups.join(',')}"
			end
		else # success
			logger.debug "SET GROUPS SUCCESS: try=#{try} #{loginfo}"
			return true
		end
	end
 end

	def self.set_extra_data(vm, key, value = nil)
	 	loginfo = "vm=#{vm} field=#{key} value=#{value}"
	 	logger.debug "SET EXTRA DATA CALLED: #{loginfo}"
	 	retry_sleep = 1
		value = value == nil ? '' : Shellwords.escape(value)
		(0..5).each do |try|
			logger.debug "SET EXTRA DATA: try=#{try} #{loginfo}"
			stdout = %x(utils/vboxmanage setextradata #{Shellwords.escape(vm)} #{Shellwords.escape(key)} #{value} 2>&1)
			if $?.exitstatus != 0
				logger.warn "SET EXTRA DATA: failed try=#{try} #{loginfo}\n #{stdout}"
				if try < 5
					sleep retry_sleep
					next  # go to next loop if not last
				else # last attempt failed
					raise "Failed to set vm extra data try=#{try}/5 field=#{key} value=#{value}"
				end
			else # success
				logger.debug "SET EXTRA DATA SUCCESS: try=#{try} #{loginfo}"
				return true
			end
		end
	end

	def self.set_network(vm, slot, type, name='')
		loginfo = "vm=#{vm} slot=#{slot} type=#{type} name=#{name}"
		logger.info "SET NETWORK CALLED: #{loginfo}"
		retry_sleep = 1
		cmd_prefix = "utils/vboxmanage modifyvm #{Shellwords.escape(vm)}"
		name = Shellwords.escape(name)
		# compile a list of commands to run based on network type (1-2 commands)
		commands = []
		if type == 'nat'
			commands << "--nic#{slot} nat"
		elsif type == 'intnet'
			commands << "--nic#{slot} intnet"
			commands << "--intnet#{slot} #{name}"
		elsif type == 'bridgeadapter'
			commands << "--nic#{slot} bridged"
			commands << "--bridgeadapter#{slot} #{name}"
		elsif type == 'hostonlyadapter'
			commands << "--nic#{slot} hostonly"
			commands << "--hostonlyadapter#{slot} #{name}"
		end
		# run each command
		commands.each do |cmnd|
			(0..5).each do |try|
				logger.debug "SET NETWORK: calling #{cmnd} try=#{try}/5 #{loginfo}"
				stdout = %x(#{cmd_prefix} #{cmnd} 2>&1 )
				# try command again if failed
				if $?.exitstatus != 0
					logger.warn "SET NETWORK: #{cmnd} failed try=#{try}/5 #{loginfo} \n#{stdout}"
					if try < 5
						sleep retry_sleep
						next  # go to next loop if not last
					else # last attempt failed
						raise "Failed to set vm network try=#{try}/5 slot=#{slot} type=#{type} name=#{name}"
					end
				else # success 
					logger.info "SET NETWORK: #{cmnd} successful try=#{try}/5 #{loginfo}"
					break # break out of the loop, continue to the next command
				end
			end # eof loop
		end # eof commands
		return true # we make it here if commands loop and the loop inside finish
 end

	def self.set_running_network(vm, slot, type, name='')
		loginfo = "vm=#{vm} slot=#{slot} type=#{type} name=#{name}"
		logger.info "SET RUNNING NETWORK CALLED: #{loginfo}"
		retry_sleep = 1
		cmd_prefix = "utils/vboxmanage controlvm #{Shellwords.escape(vm)}"
		name = Shellwords.escape(name)
		command = ''
		# choose command based on type
		if type == 'null'
			command = "nic#{slot} null"
		elsif type == 'nat'
			command = "nic#{slot} nat"
		elsif type == 'intnet'
			command = "nic#{slot} intnet #{name}"
		elsif type == 'bridgeadapter'
			command = "nic#{slot} bridged #{name}"
		elsif type == 'hostonlyadapter'
			command = "nic#{slot} hostonly #{name}"
		end
		if !command.bank?
			(0..5).each do |try|
				logger.debug "SET RUNNING NETWORK: try=#{try}/5 #{loginfo}"
				stdout = %x(#{cmd_prefix} #{command} 2>&1 )
				# try command again if failed
				if $?.exitstatus != 0
					logger.warn "SET RUNNING NETWORK: failed try=#{try}/5 #{loginfo} \n#{stdout}"
					if try < 5
						sleep retry_sleep
						next  # go to next loop if not last
					else # last attempt failed
						raise "Failed to set vm network try=#{try}/5 slot=#{slot} type=#{type} name=#{name}"
					end
				else # success 
					logger.info "SET RUNNING NETWORK SUCCESS: try=#{try}/5 #{loginfo}"
					return true
				end
			end # eof loop
		else
			raise "Unsupported network type slot=#{slot} type=#{type} name=#{name}"
		end
	end

 def self.reset_vm_rdp(vm)
	stdout = %x(utils/vboxmanage controlvm #{Shellwords.escape(vm)} vrde off 2>&1)
	if $?.exitstatus != 0
		unless stdout.start_with? "VBoxManage: error: Machine '#{vm}' is not currently running"
			logger.error "Failed to stop vm: #{stdout}"
			raise 'Failed to disable RDP'
		end
		return
	end

	stdout = %x(utils/vboxmanage controlvm #{Shellwords.escape(vm)} vrde on 2>&1)
	if $?.exitstatus != 0
		unless stdout.start_with? "VBoxManage: error: Machine '#{vm}' is not currently running"
			logger.error "Failed to stop vm: #{stdout}"
			raise 'Failed to enable RDP'
		end
	end
 end

 def self.take_snapshot(vm)
 	info = Virtualbox.get_vm_info(vm, true) # get info without searching for lab and user

 	unless info
		raise 'Failed to get VM info'
	end

	unless info['VMState'] == 'poweroff'
		raise 'Unable to take snapshot while VM is running'
	end

	vmname = vm.gsub("-template",'')
	nr = info['CurrentSnapshotName'] ? info['CurrentSnapshotName'].gsub("#{vmname}-",'').gsub('-template','').to_i + 1 : 1
 	name = "#{vmname}-#{nr}-template"

	stdout = %x(utils/vboxmanage snapshot #{Shellwords.escape(vm)} take #{Shellwords.escape(name)} --description "#{Time.now}" 2>&1)
	if $?.exitstatus != 0
		logger.error "Failed to take snapshot: #{stdout}"
		raise 'Failed to take snapshot'
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
				result = []
				keys = chunk.split('')
				keys.each do |l|
					l = 'space' if l==' '
					l = 'quote' if l=='"'
					l = 'apostrophe' if l=="'"
					l = 'tick' if l=='`'
					l = 'backspace' if l=='\\' || l.ord == 92
					l = 'pound' if l=='#'
					raise "unknown key #{l}" unless codes[l]
					result << codes[l].join(' ')
				end
			 	stdout = %x(utils/vboxmanage controlvm #{Shellwords.escape(vm)} keyboardputscancode #{result.join(' ')} 2>&1)
				if $?.exitstatus != 0
					raise 'Failed to send text to vm'
				end
				sleep 0.2
			end
			# put line return if there are more rows after this one
			if lines[index+1]
			 	stdout = %x(utils/vboxmanage controlvm #{Shellwords.escape(vm)} keyboardputscancode #{codes['enter'].join(' ')} 2>&1)
				if $?.exitstatus != 0
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
	 	result = []
	 	# press down
	 	keys.each do |l|
	 		raise "unknown key #{l}" unless codes[l]
	 		result << codes[l][0]
	 	end
	 	logger.info "keyboardputscancode #{result.join(' ')}"
	 	stdout = %x(utils/vboxmanage controlvm #{Shellwords.escape(vm)} keyboardputscancode #{result.join(' ')} 2>&1)
		if $?.exitstatus != 0
			raise 'Failed to send keys to vm'
		end
		sleep 0.2
		result = []
	 	#release
	 	keys.each do |l|
	 		raise "unknown key #{l}" unless codes[l]
	 		result << codes[l][1]
	 	end
	 	logger.info "keyboardputscancode #{result.join(' ')}"
	 	stdout = %x(utils/vboxmanage controlvm #{Shellwords.escape(vm)} keyboardputscancode #{result.join(' ')} 2>&1)
		if $?.exitstatus != 0
			raise 'Failed to send keys to vm'
		end
		{success: true, message: "Keys successfully sent"}
	rescue Exception => e 
		logger.error e.to_s
		return {success: false, message: e.message || 'unexpected error while sending keys' }
	end
 end


end

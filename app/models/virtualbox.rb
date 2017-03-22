class Virtualbox < ActiveRecord::Base

# this is a class to activate different command-line vboxmanage commands and translate the results for the rails app

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
	stdout = %x(utils/vboxmanage showvminfo #{Shellwords.escape(name)} --machinereadable 2>&1)
	unless $?.exitstatus == 0
		if stdout.lines.first == "VBoxManage: error: Could not find a registered machine named '#{name}'\n"
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
					vm.merge!(Lab.select('id, name').where("id=?", vmt.lab_id).first.as_json)
				end
			end
			username = vm['groups'][1] ? vm['groups'][1].gsub('/', '').strip : '' # second group is user name
			if username != ''
				user = User.select('id, username, name').where('username=?', username).first
				if user
					vm.merge!(user.as_json)
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
  def self.remote(typ, port, user)
    
    begin
      rdp_host=ITee::Application.config.rdp_host
    rescue
      rdp_host=`hostname -f`.strip
    end

    case typ
      when 'win'
        desc = "cmdkey /generic:#{rdp_host} /user:localhost&#92;#{user.username} /pass:#{user.rdp_password}&amp;&amp;"
        desc += "mstsc.exe /v:#{rdp_host}:#{port} /f"
      when 'rdesktop'
        desc ="rdesktop  -u#{user.username} -p#{user.rdp_password} -N -a16 #{rdp_host}:#{port}"
      when 'xfreerdp'
        desc ="xfreerdp  --plugin cliprdr -g 90% -u #{user.username} -p #{user.rdp_password} #{rdp_host}:#{port}"
      when 'mac'
        desc ="open rdp://#{user.username}:#{user.rdp_password}@#{rdp_host}:#{port}"
      else
        desc ="rdesktop  -u#{user.username} -p#{user.rdp_password} -N -a16 #{rdp_host}:#{port}"
    end

  end

 def self.open_guacamole(vm, user)
	if user.rdp_password==""
		raise 'Please generate a rdp password'
	end

	machine =  Virtualbox.get_vm_info(vm, true)
	# check if vm has guacamole enabled
	unless machine['VMState']=='running'
		raise 'please start this virtual machine before trying to establish a connection'
	end

	begin
		chost = ITee::Application::config.guacamole[:rdp_host]
	rescue
		logger.warn "RDP host for Guacamole not specified"
		chost = ITee::Application::config.rdp_host
	end
	cport =  machine['vrdeport'].to_i
	cusername = gusername = user.username
	cpassword = user.rdp_password
	cname = vm

	cipher = OpenSSL::Cipher.new('aes-256-gcm');
	cipher.encrypt
	cipher.key = ITee::Application::config.guacamole[:initializer_key]
	iv = cipher.iv = cipher.random_iv
	encrypted = cipher.update(JSON.generate({
		:name => cname,
		:type => 'rdp',
		:hostname => chost,
		:port => cport,
		:username => cusername,
		:password => cpassword,
		:"guacamole-username" => gusername
	})) + cipher.final
	tag = cipher.auth_tag

	message = Base64.strict_encode64(iv + tag + encrypted);

	return ITee::Application::config.guacamole[:initializer_url] + '/' + message;
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
	stdout = %x(utils/vboxmanage startvm #{Shellwords.escape(vm)} --type headless  2>&1)
	if $?.exitstatus != 0
		unless stdout.start_with? "VBoxManage: error: The machine '#{vm}' is already locked by a session (or being locked or unlocked)\n"
			logger.error "Failed to start vm: #{stdout}"
			raise 'Failed to start vm'
		end
	end
 end

 def self.stop_vm(vm)
	stdout = %x(utils/vboxmanage controlvm #{Shellwords.escape(vm)} poweroff 2>&1)
	if $?.exitstatus != 0
		unless stdout == "VBoxManage: error: Machine '#{vm}' is not currently running\n"
			logger.error "Failed to stop vm: #{stdout}"
			raise 'Failed to stop vm'
		end
	end
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
	stdout = %x(utils/vboxmanage unregistervm #{Shellwords.escape(vm)} --delete 2>&1)
	if $?.exitstatus != 0
		logger.error "Failed to delete vm: #{stdout}"
		raise 'Failed to delete vm'
	end
 end

 def self.clone(vm, name, snapshot = '')
	if snapshot
		stdout = %x(utils/vboxmanage clonevm #{Shellwords.escape(vm)} --snapshot #{Shellwords.escape(snapshot)} --options link --name #{Shellwords.escape(name)} --register 2>&1)
	else
		stdout = %x(utils/vboxmanage clonevm #{Shellwords.escape(vm)} --name #{Shellwords.escape(name)} --register 2>&1)
	end
	if $?.exitstatus != 0
		logger.error "Failed to clone vm: #{stdout}"
		raise 'Failed to clone vm'
	end
 end

 def self.set_groups(vm, groups)
	stdout = %x(utils/vboxmanage modifyvm #{Shellwords.escape(vm)} --groups #{Shellwords.escape(groups.join(','))} 2>&1)
	if $?.exitstatus != 0
		logger.error "Failed to set vm groups: #{stdout}"
		raise 'Failed to set vm groups'
	end
 end

 def self.set_extra_data(vm, key, value = nil)
	value = value == nil ? '' : Shellwords.escape(value)
	stdout = %x(utils/vboxmanage setextradata #{Shellwords.escape(vm)} #{Shellwords.escape(key)} #{value} 2>&1)
	if $?.exitstatus != 0
		logger.error "Failed to set vm extra data: #{stdout}"
		raise 'Failed to set vm extra data'
	end
 end

 def self.set_network(vm, slot, type, name='')
	cmd_prefix = "utils/vboxmanage modifyvm #{Shellwords.escape(vm)}"
	name = Shellwords.escape(name)

	if type == 'nat'
		stdout = %x(#{cmd_prefix} --nic#{slot} nat 2>&1)
	elsif type == 'intnet'
		stdout = %x(#{cmd_prefix} --nic#{slot} intnet 2>&1 &&
		            #{cmd_prefix} --intnet#{slot} #{name} 2>&1)
	elsif type == 'bridgeadapter'
		stdout = %x(#{cmd_prefix} --nic#{slot} bridged 2>&1 &&
		            #{cmd_prefix} --bridgeadapter#{slot} #{name} 2>&1)
	elsif type == 'hostonlyadapter'
		stdout = %x(#{cmd_prefix} --nic#{slot} hostonly 2>&1 &&
		            #{cmd_prefix} --hostonlyadapter#{slot} #{name} 2>&1)
	end
	if $?.exitstatus != 0
		logger.error "Failed to set vm network: #{stdout}"
		raise 'Failed to set vm network'
	end
 end

 def self.reset_vm_rdp(vm)
	stdout = %x(utils/vboxmanage controlvm #{Shellwords.escape(vm)} vrde off 2>&1)
	if $?.exitstatus != 0
		unless stdout == "VBoxManage: error: Machine '#{vm}' is not currently running\n"
			logger.error "Failed to stop vm: #{stdout}"
			raise 'Failed to disable RDP'
		end
		return
	end

	stdout = %x(utils/vboxmanage controlvm #{Shellwords.escape(vm)} vrde on 2>&1)
	if $?.exitstatus != 0
		unless stdout == "VBoxManage: error: Machine '#{vm}' is not currently running\n"
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
end

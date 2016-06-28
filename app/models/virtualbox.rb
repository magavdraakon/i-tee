class Virtualbox < ActiveRecord::Base

# this is a class to activate different command-line vboxmanage commands and translate the results for the rails app

def self.get_machines(state='', where={}, sort='')
	unless where
		where={}
	end
	logger.debug "state is '#{state}'"
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

    # TODO get additional info
    vms_info=[]
    vms.each do |vm|
    	add = true
    	if where.key?(:name) && where[:name]!=''# check if name is similar
    		add = vm.downcase.include? where[:name].downcase
    	end
    	if add
	    	info = Virtualbox.get_vm_info(vm)  # get detiled info
	    	if where.key?(:VRDEActiveConnection) # check if connection is active
	    		if where[:VRDEActiveConnection]=="any"
	    			add=true
	    		else
	    			add = where[:VRDEActiveConnection] == info['VRDEActiveConnection']
	    		end
	    	end

	    	if add && where.key?(:group) && where[:group]!=''
	    		add = info['groups'] ? info['groups'].any? {|group| group.downcase.include? where[:group].downcase} : false
	    	end

	    	vms_info << info if add
	    end
    end
    vms_info
end

def self.running_machines
	info = %x(sudo -u vbox VBoxManage list runningvms | cut -f1 -d' '| tr -d '"' )
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
	info = %x(sudo -u vbox VBoxManage list vms | cut -f1 -d' '| tr -d '"' )
	status = $?
	#logger.debug info
	if status.exitstatus===0
		info.split(/\n+/)
	else
		false
	end
end

def self.template_machines
	info = %x(sudo -u vbox VBoxManage list vms | grep template|cut -d' ' -f1|tr '"' ' ')
	status= $?
	#logger.debug info
	if status.exitstatus===0
		info.split(/\n+/)
	else
		false
	end
end

def self.get_vm_info(name)
	info = %x(sudo -u vbox VBoxManage showvminfo #{name} --machinereadable )
	status = $?
	#logger.debug info
	vm = {}
	if status.exitstatus===0
		info.split(/\n+/).each do |row|
			if row.strip!=''
				#puts row
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

				#puts "\nfield #{field}"
				#puts "value #{value}"
				#puts "subfield #{subfield}" if subfield
				#puts "subfield field #{subsub}" if subsub

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
		end

		vm
	else
		false
	end
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

  def self.manage_vms(vms, act)
  	result = {'success'=>true, 'message' => '', 'errors'=>[]}
  	vms.each do |vm|
  		case act
        when 'start'
          r = Virtualbox.start_vm(vm)
        when 'stop'
          r = Virtualbox.stop_vm(vm)
        when 'pause'
          r = Virtualbox.pause_vm(vm)
        when 'resume'
          r = Virtualbox.resume_vm(vm)
        when 'reset_rdp'
          r= Virtualbox.reset_vm_rdp(vm)
        else
          r = {'success'=>false, 'message' => "unknown action"}
        end
        if r
        	if r['success']
        		result['message']=result['message'] + (result['message']=='' ? '' : '<br/> ')+ r['message']
        	else
        		result['errors']<<r['message']
        	end
        else
        	result['errors']<< "unable to #{act} vm #{vm}"
        end
    end
    if result['errors'].count>0
    	result['success'] = false
    	result['message'] = result['message']+ "<br/><b>errors</b>:<br/> "+result['errors'].join('<br/>')
    end
    result
  end

 def self.start_vm(vm)
 	info = %x(sudo -u vbox VBoxManage startvm #{vm} --type headless  2>&1)
	status= $?
	#logger.debug info
	#logger.debug status
	if status.exitstatus===0
		{'success'=>true, 'message'=> "successfully to started #{vm}"}
	else
		if info.include? "is already locked by a session"
			{'success'=>false, 'message'=> "unable to start #{vm} - it is already running"}
		else
			{'success'=>false, 'message'=> "unable to start #{vm}"}
		end
	end
 end

 def self.stop_vm(vm)
 	info = %x(sudo -u vbox VBoxManage controlvm #{vm} poweroff 2>&1)
	status= $?
	#logger.debug info
	#logger.debug status
	if status.exitstatus===0
		{'success'=>true, 'message'=> "successfully to stopped #{vm}"}
	else
		if info.include? "is not currently running"
			{'success'=>false, 'message'=> "unable to stop #{vm} - it is already powered off"}
		else
			{'success'=>false, 'message'=> "unable to stop #{vm}"}
		end
	end
 end

 def self.pause_vm(vm)

 end

 def self.resume_vm(vm)

 end

 def self.reset_vm_rdp(vm)
 	info = %x(sudo -u vbox VBoxManage controlvm #{vm} vrde off 2>&1)
	status= $?
	#logger.debug info
	#logger.debug status
	if status.exitstatus===0
		info = %x(sudo -u vbox VBoxManage controlvm #{vm} vrde on 2>&1)
		status= $?
		#logger.debug info
		#logger.debug status
		if status.exitstatus===0
			{'success'=>true, 'message'=> "RDP successfully to reset for #{vm}"}
		else
			if info.include? "is not currently running"
				{'success'=>false, 'message'=> "unable to reset RDP for #{vm} - it is not running"}
			else
				{'success'=>false, 'message'=> "unable to reset RDP for #{vm}"}
			end
		end
	else
		if info.include? "is not currently running"
			{'success'=>false, 'message'=> "unable to reset RDP for #{vm} - it is not running"}
		else
			{'success'=>false, 'message'=> "unable to reset RDP for #{vm}"}
		end
	end
 end


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
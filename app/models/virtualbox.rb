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

	    	if where.key?(:lab) && where[:lab]!='' # only for this lab
		    	add = info['lab'] ? info['lab']['id'].to_i == where[:lab].to_i : false
		    end
		    if where.key?(:user) && where[:user]!='' # only for this user
		    	add = info['user'] ? info['user']['id'].to_i == where[:user].to_i : false
		    end
	    	if add && where.key?(:group) && where[:group]!=''
	    		add = info['groups'] ? info['groups'].any? {|group| group.downcase.include? where[:group].downcase} : false
	    	end

	    	if add && where.key?(:VRDEActiveConnection) # check if connection is active
	    		if where[:VRDEActiveConnection]=="any"
	    			add = true
	    		else
	    			add = where[:VRDEActiveConnection] == info['VRDEActiveConnection']
	    		end
	    	end

	    	vms_info << info if add
	    end
    end
    vms_info
end

def self.running_machines
	info = %x(sudo -Hu vbox VBoxManage list runningvms | cut -f2 -d'"')
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
	info = %x(sudo -Hu vbox VBoxManage list vms | cut -f2 -d'"')
	status = $?
	#logger.debug info
	if status.exitstatus===0
		info.split(/\n+/)
	else
		false
	end
end

def self.template_machines
	info = %x(sudo -Hu vbox VBoxManage list vms | grep template | cut -f2 -d'"')
	status= $?
	#logger.debug info
	if status.exitstatus===0
		info.split(/\n+/)
	else
		false
	end
end

def self.get_vm_info(name, static=false)
	info = %x(sudo -Hu vbox VBoxManage showvminfo #{Shellwords.escape(name)} --machinereadable )
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
			unless static
				vmname = vm['groups'][0] ? vm['groups'][0].gsub('/', '').strip : '' # first group is machine name
				if vmname!='' 
					vmt = LabVmt.where('name=?', vmname).first
					if vmt
						vm.merge!(Lab.select('id, name').where("id=?", vmt.lab_id).first.as_json)
					end
				end
				username = vm['groups'][1] ? vm['groups'][1].gsub('/', '').strip : '' # second group is user name
				if username!='' 
					user = User.select('id, username, name').where('username=?', username).first
					if user
						vm.merge!(user.as_json)
					end
				end
			end
		end

		if vm['CurrentSnapshotNode']
			vm['CurrentSnapshotDescription']=vm[vm['CurrentSnapshotNode'].gsub('Name', 'Description')]
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

def self.open_guacamole(vm, user)
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

        g_username = user_prefix+user.username
        g_password = user.rdp_password
        g_name = user_prefix+vm
        # check if the user has a guacamole user
        g_user = GuacamoleUser.where("username = ?", g_username ).first
        unless g_user
          # create user
          g_user = GuacamoleUser.create(username: g_username, password_hash:  g_password, timezone: 'Etc/GMT+0')
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
        # check if there is a connection
        g_conn = GuacamoleConnection.where("connection_name = ? ", g_name ).first
        unless g_conn # find by full name
          # create connection
          # data format {connection_name, protocol, max_connections, max_connections_per_user, params {hostname, port, username, password, color-depth}
          g_conn = GuacamoleConnection.create( connection_name: g_name, 
            protocol: 'rdp' , 
            max_connections: max_connections, 
            max_connections_per_user: max_user_connections )
         
          if g_conn
            g_conn.add_parameters([
              { parameter_name: 'hostname', parameter_value: rdp_host },
              { parameter_name: 'port', parameter_value: rdp_port },
              { parameter_name: 'username', parameter_value: g_username },
              { parameter_name: 'password', parameter_value: g_password },
#             { parameter_name: 'color-depth', parameter_value: 255 }
            ])
          else
            logger.debug g_conn
            return {success: false, message: 'unable to create connection in guacamole'} 
          end
        else # connection existed
          #the port had changed?- change row where connection id is x and parameter is 'port'
          # find parameter 
          param = GuacamoleConnectionParameter.where("connection_id=? and parameter_name=?", g_conn.connection_id, 'port').first
          if param #update
            GuacamoleConnectionParameter.where("connection_id=? and parameter_name=?", g_conn.connection_id, 'port').limit(1).update_all(parameter_value: rdp_port)
          else # create
            GuacamoleConnectionParameter.create(connection_id: g_conn.connection_id, parameter_name: 'port', parameter_value: rdp_port )
          end

          # password had changed?
          param = GuacamoleConnectionParameter.where("connection_id=? and parameter_name=?", g_conn.connection_id, 'password').first
          if param #update
            GuacamoleConnectionParameter.where("connection_id=? and parameter_name=?", g_conn.connection_id, 'password').limit(1).update_all(parameter_value: g_password)
          else # create
            GuacamoleConnectionParameter.create(connection_id: g_conn.connection_id, parameter_name: 'password', parameter_value: g_password )
          end
          
        end #EOF connection check
        # check if the connection persist/has been created
        if g_conn
          # allow connection if none exists
          permission = GuacamoleConnectionPermission.where("user_id=? and connection_id=? and permission=?", g_user.user_id, g_conn.connection_id , 'READ').first
          unless permission # if no permission, create one
            result = GuacamoleConnectionPermission.create(user_id: g_user.user_id, connection_id: g_conn.connection_id, permission: 'READ')
            unless result
              return {success: false, message: 'unable to allow connection in guacamole'} 
            end
          end
          # log in 
          post = Http.post(url_prefix + "/api/tokens", {username: g_username, password: g_password})
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
      	when 'take_snapshot'
      	  r= Virtualbox.take_snapshot(vm)
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
	info = %x(sudo -Hu vbox VBoxManage startvm #{Shellwords.escape(vm)} --type headless  2>&1)
	status= $?
	logger.debug info
	logger.debug status
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
	info = %x(sudo -Hu vbox VBoxManage controlvm #{Shellwords.escape(vm)} poweroff 2>&1)
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
	info = %x(sudo -Hu vbox VBoxManage controlvm #{Shellwords.escape(vm)} vrde off 2>&1)
	status= $?
	#logger.debug info
	#logger.debug status
	if status.exitstatus===0
		info = %x(sudo -Hu vbox VBoxManage controlvm #{Shellwords.escape(vm)} vrde on 2>&1)
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

 def self.take_snapshot(vm)
 	info = Virtualbox.get_vm_info(vm, true) # get info without searching for lab and user
 	if info
 		if info['VMState']=='poweroff'
	 		vmname=vm.gsub("-template",'')
	 		nr = info['CurrentSnapshotName'] ? info['CurrentSnapshotName'].gsub("#{vmname}-",'').gsub('-template','').to_i+1 : 1
		 	name = "#{vmname}-#{nr}-template"

			info = %x(sudo -Hu vbox VBoxManage snapshot #{Shellwords.escape(vm)} take #{Shellwords.escape(name)} --description "#{Time.now}" )
			status= $?
			logger.debug info
			logger.debug status
			if status.exitstatus===0
				{'success'=>true, 'message'=> "snapshot of #{vm} successfully created"}
			else
				{'success'=>false, 'message'=> "unable to take snapshot of #{vm}"}
			end
		else
			{'success'=>false, 'message'=> "unable to take snapshot of #{vm} while it is running"}
		end
	else
		{'success'=>false, 'message'=> "unable to find #{vm}"}
	end
 end


# create the password hash to be fed to the set_password method
def self.create_password_hash(username, password)
	info = Digest::SHA256.hexdigest(password)
	"VBoxAuthSimple/users/#{username} #{info}".strip
end

# set password for vms
# TODO: allow sending a list of vm-s instead of applying to all machines
def self.set_password(hash)
	info = %x(sudo -Hu vbox VBoxManage list vms| cut -f1 -d' '| tr -d '"' )
	status = $?
	error=false
	# logger.debug info
	info.split(/\n+/).each do |line|
		#puts "vm is: #{line}"
		ex = %x(sudo -Hu vbox VBoxManage setextradata #{Shellwords.escape(line)} #{hash})
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
	info = %x(sudo -Hu vbox VBoxManage list vms| cut -f1 -d' '| tr -d '"' )
	status = $?
	error=false
	# logger.debug info
	info.split(/\n+/).each do |line|
		#puts "vm is: #{line}"
		ex = %x(sudo -Hu vbox VBoxManage setextradata #{Shellwords.escape(line)} #{Shellwords.escape("VBoxAuthSimple/users/#{username}")})
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

class Vm < ActiveRecord::Base
  has_one :mac
  belongs_to :user
  belongs_to :lab_vmt
  belongs_to :lab_user
  before_destroy :del_vm
  before_destroy :rel_mac
  before_create :add_pw
  
  validates_presence_of :name, :lab_vmt_id, :user_id
  validates_uniqueness_of :name
  def rel_mac
    logger.debug "\n trying to release mac for #{self.id} - #{self.name} \n"
    mac=Mac.where('vm_id=?', self.id).first
    if mac
      mac.vm_id=nil
      mac.save
      logger.debug "mac released from #{self.id} - #{self.name}\n"
    else
      logger.debug "\n no mac \n"
    end
  end

  def add_pw
    chars = 'abcdefghjkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789'
    self.password = ''
    8.times { |i| self.password << chars[rand(chars.length)] }
  end

  #TODO does not work as desired
  if ITee::Application::config.respond_to? :cmd_perfix
    @exec_line = ITee::Application::config.cmd_perfix.chomp
  else
    @exec_line = 'sudo -Hu vbox '
  end


  def del_vm
     %x(sudo -Hu vbox #{Rails.root}/utils/delete_machine.sh #{name}  2>&1)
  end
  
  def poweroff_vm
    #TODO script .. pooleli
     %x(sudo -Hu vbox #{Rails.root}/utils/stop_machine.sh #{name}  2>&1)
  end
  
  def poweron_vm
    #TODO script .. pooleli
    %x("sudo -Hu vbox  #{Rails.root}/utils/poweron_machine.sh #{name}  2>&1".strip)
  end
  
  def res_vm
    %x(sudo -Hu vbox #{Rails.root}/utils/resume_machine.sh #{name}  2>&1)
  end
  
  def pau_vm
    %x(sudo -Hu vbox #{Rails.root}/utils/pause_machine.sh #{name}  2>&1)
  end

  def res_rdp
    info = %x(sudo -Hu vbox #{Rails.root}/utils/reset_vbox_rdp.sh #{name}  2>&1)
    status= $?
    {status: status.exitstatus, answer: info}
  end

  def reset_rdp
    result = self.res_rdp
    logger.debug result
    if result[:status]==0
      {success: true, message: "Vm rdp reset successful"}
    else
      {success: true, message: "Vm rdp reset failed"}
    end
  end
  
  def ini_vm
    begin
      rdp_host=ITee::Application.config.rdp_host
    rescue
      rdp_host=`hostname -f`.strip
    end
    
    runstr = "sudo -Hu vbox  #{Rails.root}/utils/start_machine.sh #{rdp_host} #{mac.ip} #{lab_vmt.vmt.image} #{name} #{password} #{ENV['ENVIRONMENT']} '#{user.name}' 2>&1"
    Rails.logger.debug "ini_vm: #{runstr}"
    %x(#{runstr})
    #%x("#{@exec_line}  #{Rails.root}/utils/start_machine.sh #{mac.mac} #{mac.ip} #{lab_vmt.vmt.image} #{name} #{password} 2>&1")
  end
  
  def state
    ret = %x[sudo -Hu vbox /usr/bin/VBoxManage showvminfo #{name}|grep -E '^State:']
    r = "#{ret}".split(' ')[1]

    #Rails.logger.warn ret.split(' ')[1]
    Rails.logger.warn "VM #{name} state is: #{r}"
    case r
    when 'running'
      return 'running'
    when 'paused'
      return 'paused'
    when 'powered'
      return 'stopped'
    else
      return 'stopped'
    end
  end

  def stop_vm
   if self.state=='running' || self.state=='paused'
    logger.info 'Running VM power off script'
    a=self.poweroff_vm #the script is called in the model
    logger.info a
    self.description='Power on the virtual machine by clicking <strong>Start</strong>.'
    self.save
    # remove link to  mac 
    @mac = Mac.where('vm_id=?', self.id).first
    @mac.vm_id=nil
    @mac.save
    {success: true, message: 'Successful macine shutdown'}
  else
    {success: true, message: 'Machine was already shut down'}
  end
end

  def start_vm
    #find out if there is a mac address bound with this vm already
    result = {notice: '', alert: ''}
    @mac= Mac.where('vm_id=?', self.id).first
    # binding a unused mac address with the vm if there is no mac
    if @mac==nil
      @mac= Mac.where('vm_id is null').first
      @mac.vm_id=self.id
      if @mac.save  #save successful
        logger.debug '\n successful mac assignement.\n'
      end #end -if save
    else
      #the vm had a mac already, dont do anything
      logger.debug '\nVm already had a mac.\n'
    end # end if nil
      
    if self.state!='running' && self.state!='paused'
      logger.info 'running Machine start script'

      ###########################################################
      #Create custom environment file for start_machine.sh script
      ###########################################################

      #customization script is stored into run_dir (application config)

      # fallback name if run_dir is missing from application config
      customization_file='/var/labs/'
      if ITee::Application::config.respond_to? :run_dir
        customization_file="#{ITee::Application.config.run_dir}/"
      end

      customization_file += "#{name}.sh"

      begin
      File.open(customization_file, 'w+') { |f|
        #Writing VM data
        f.write("#Configuration file for VM: #{name}\n")
        f.write("export NIC1='#{Rails.root}'\n")
        f.write("#NIC count #{self.lab_vmt.lab_vmt_networks.count}\n\n")

        if self.lab_vmt.lab_vmt_networks.count > 0
          f.write("function set_networks {\n\n#function for seting NICs for VM")
          #Writing NIC information
          vbox_cmd = ''
          self.lab_vmt.lab_vmt_networks.each do |nw|
            # substituting placeholders with data
            gen_name=nw.network.name.gsub('{year}', Time.now.year.to_s)
            gen_name= gen_name.gsub('{user}', self.user.username)
            gen_name= gen_name.gsub('{slot}', nw.slot.to_s)
            gen_name= gen_name.gsub('{labVmt}', self.lab_vmt.name)

            logger.debug "\nNIC#{nw.slot} #{gen_name} net type #{nw.network.net_type}\n"
            if nw.network.net_type == 'nat'
              vbox_cmd += "VBoxManage modifyvm \"$NAME\" --nic#{nw.slot} nat\n"
            elsif nw.network.net_type == 'intnet'
              vbox_cmd = "VBoxManage modifyvm \"$NAME\" --nic#{nw.slot} intnet\n"
              vbox_cmd += "VBoxManage modifyvm \"$NAME\"  --intnet#{nw.slot} \"#{gen_name}\"\n"
            elsif nw.network.net_type == 'bridgeadapter'
              vbox_cmd = "VBoxManage modifyvm \"$NAME\" --nic#{nw.slot} bridged\n"
              vbox_cmd += "VBoxManage modifyvm \"$NAME\"  --bridgeadapter#{nw.slot} \"#{gen_name}\"\n"
            elsif nw.network.net_type == 'hostonlyadapter'
              vbox_cmd = "VBoxManage modifyvm \"$NAME\" --nic#{nw.slot} hostonly\n"
              vbox_cmd += "VBoxManage modifyvm \"$NAME\"  --hostonlyadapter#{nw.slot} \"#{gen_name}\"\n"
            end
            logger.debug vbox_cmd
            f.write("\n#{vbox_cmd}\n")
            vbox_cmd =''

          end
          f.write("\n"'echo "networks are now configured for $NAME"')
          f.write("\n}\n\n")
          #end for fuction set networks
        end



      }
      rescue
        Rails.logger.error("Can't open file #{customization_file} for writing!")
      else
        Rails.logger.info("Writing configuration to #{customization_file}")
      end




      @ini_result=self.ini_vm #the script is called in the model
=begin
      port=@mac.ip.split('.').last
      begin
        rdp_host=ITee::Application.config.rdp_host
      rescue
        rdp_host=`hostname -f`.strip
      end
      begin
        rdp_port_prefix = ITee::Application.config.rdp_port_prefix
      rescue
        rdp_port_prefix = '10'
      end
=end
      
      desc = 'To create a connection with this machine using linux/unix use<br/>'
      desc += '<srong>'+self.remote('rdesktop')+'</strong>' 
      desc += '<br/> or use xfreerdp as<br/>'
      desc += '<srong>'+self.remote('xfreerdp')+'</strong>' 
      #"<strong>rdesktop -k et -u#{self.user.username} -p#{self.password} -N -a16 #{rdp_host}:#{rdp_port_prefix}#{port}</strong></br> or use xfreerdp as</br><strong>xfreerdp  -k et --plugin cliprdr -g 90% -u #{self.user.username} -p #{self.password} #{rdp_host}:#{rdp_port_prefix}#{port}</strong></br>"
      
      desc +=  '<br/>To create a connection with this machine using Windows use two commands:<br/>'
      desc += '<srong>'+self.remote('win')+'</strong>' #"<strong>cmdkey /generic:#{rdp_host} /user:localhost\\#{self.user.username} /pass:#{self.password}</strong><br/>"
      #desc += "<strong>mstsc.exe /v:#{rdp_host}:#{rdp_port_prefix}#{port} /f</strong><br/>"
      logger.debug "\n setting #{self.id} description to \n #{desc}"
      self.description = desc

      self.save
      logger.debug "\n save successful "
=begin
      require 'timeout'
      status = Timeout::timeout(60) {
        # Something that should be interrupted if it takes too much time...
        if @ini_result!=nil
          until @ini_result.include?("masin #{self.name} loodud")
          #do nothing, just wait
            sleep(5)
            logger.debug "\nwaiting ...\n"
          end
        end
      }
=end
      if @ini_result.include?("VM named: #{self.name} created")
        result[:notice] = result[:notice]+"Machine <b>#{self.lab_vmt.nickname}</b> successfully started<br/>"
        #flash[:notice]=flash[:notice].html_safe
        logger.debug @ini_result

        # add last activity to labuser
        labuser=LabUser.where('lab_id=? and user_id=?', self.lab_vmt.lab_id, self.user_id).last
        if labuser
          labuser.last_activity=Time.now
          labuser.activity="Start vm - '#{self.name}'"
          labuser.save 
        end

      else
        logger.info @ini_result
        @mac.vm_id=nil
        @mac.save
        result[:notice] = ''
        result[:alert]="Machine <b>#{self.lab_vmt.nickname}</b> initialization <b>failed</b>."
      end
     # logger.debug "\n#{result}\n"
    else
      result[:notice] = ''
      result[:alert]="Unable to start <b>#{self.lab_vmt.nickname}</b>, it is already running"
    end
    result
    # removed mac address conflict rescue. Conflict management is TODO!
  end


  #pause a machine
  def pause_vm
    if self.state=='running'
      logger.info 'running VM pause script'
      a = self.pau_vm #the script is called in the model
      logger.info a
      {success: true, message: 'Successful vm pause.'}
    elsif self.state=='paused'
      {success: false, message:'Unable to pause a paused machine'}
    else
      {success: false, message: 'unable to pause a shut down machine'}
    end
  end

  #resume machine from pause
  def resume_vm
    if self.state=='paused'
      logger.info 'running VM resume script'
      a=self.res_vm # the script is called in the model
      logger.info a
      {success: true, message: 'Successful vm resume.'}
    elsif self.state=='running'
      return {success: false, message:'Unable to resume a running machine'}
    else
      {success: false, message: 'unable to resume a shut down machine'}
    end
  end


  def get_all_rdp
    [
      {os: ['Windows'], program: '', rdpline: self.remote('win') },
      {os: ['Linux', 'UNIX'], program: 'xfreerdp', rdpline: self.remote('xfreerdp') },
      {os: ['Linux', 'UNIX'], program: 'rdesktop', rdpline: self.remote('rdesktop') },
      {os: ['MacOS'], program: '', rdpline: self.remote('mac') }
    ]
  end

  def get_connection_info
    port=self.mac ? self.mac.ip.split('.').last : ''
    begin
      rdp_host=ITee::Application.config.rdp_host
    rescue
      rdp_host=`hostname -f`.strip
    end
    begin
      rdp_port_prefix = ITee::Application.config.rdp_port_prefix
    rescue
      rdp_port_prefix = '10'
    end

    info = { }
    info[:username] = self.user.username
    info[:password] = self.password
    info[:host] = rdp_host
    info[:port] = "#{rdp_port_prefix}#{port}"

    info
  end

  # connection informations
  def remote(typ, resolution='')
    if resolution!="" 
      logger.debug "\n resolution is #{resolution}"
    end
    port=self.mac ? self.mac.ip.split('.').last : ''
    begin
      rdp_host=ITee::Application.config.rdp_host
    rescue
      rdp_host=`hostname -f`.strip
    end
    begin
      rdp_port_prefix = ITee::Application.config.rdp_port_prefix
    rescue
      rdp_port_prefix = '10'
    end

    case typ
      when 'win'
        desc = "cmdkey /generic:#{rdp_host} /user:localhost&#92;#{self.user.username} /pass:#{self.password}&amp;&amp;"
        desc += "mstsc.exe /v:#{rdp_host}:#{rdp_port_prefix}#{port} /f"
      when 'rdesktop'
        desc ="rdesktop  -u#{self.user.username} -p#{self.password} -N -a16 #{rdp_host}:#{rdp_port_prefix}#{port}"
      when 'xfreerdp'
        desc ="xfreerdp  --plugin cliprdr -g 90% -u #{self.user.username} -p #{self.password} #{rdp_host}:#{rdp_port_prefix}#{port}"
      when 'mac'
        desc ="open rdp://#{self.user.username}:#{self.password}@#{rdp_host}:#{rdp_port_prefix}#{port}"
      else
        desc ="rdesktop  -u#{self.user.username} -p#{self.password} -N -a16 #{rdp_host}:#{rdp_port_prefix}#{port}"
    end

  end

  def open_guacamole
    # check if vm has guacamole enabled
    if self.state=='running'
      if self.lab_vmt.allow_remote && self.lab_vmt.guacamole_type!="none"

        port = self.mac ? self.mac.ip.split('.').last : ''
        rdp_port_prefix = ITee::Application.config.rdp_port_prefix
        rdp_port = "#{rdp_port_prefix}#{port}".to_i

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



        # check if the labuser has a guacamole user
        unless self.lab_user.g_user && GuacamoleUser.find(self.lab_user.g_user)
          # create user
          self.lab_user.g_username = user_prefix+"#{self.lab_user.id}"
          self.lab_user.g_password = SecureRandom.base64
          result = GuacamoleUser.create(username: self.lab_user.g_username, password_hash: self.lab_user.g_password, timezone: 'Etc/GMT+0')
          if result
            # save to labuser
            self.lab_user.g_user = result.user_id
            self.lab_user.save
          else 
            logger.debug result
            return {success: false, message: 'unable to add user to guacamole'} 
          end
        end # has no user
        # check if there is a connection
        unless self.g_connection && GuacamoleConnection.find(self.g_connection)
          # create connection
          # data format {connection_name, protocol, max_connections, max_connections_per_user, params {hostname, port, username, password, color-depth}}
          
          result = GuacamoleConnection.create( connection_name: user_prefix+self.name, 
            protocol: self.lab_vmt.guacamole_type , 
            max_connections: max_connections, 
            max_connections_per_user: max_user_connections )
          
          if result
            result.add_parameters([
              { parameter_name: 'hostname', parameter_value: rdp_host },
              { parameter_name: 'port', parameter_value: rdp_port },
              { parameter_name: 'username', parameter_value: self.user.username },
              { parameter_name: 'password', parameter_value: self.password },
#             { parameter_name: 'color-depth', parameter_value: 255 }
            ])
            self.g_connection = result.connection_id
            self.save
          else
            logger.debug result
            return {success: false, message: 'unable to create connection in guacamole'} 
          end
        else # connection existed
          #the port had changed?- change row where connection id is x and parameter is 'port'
          # find parameter 
          param = GuacamoleConnectionParameter.where("connection_id=? and parameter_name=?", self.g_connection, 'port').first
          if param #update
            GuacamoleConnectionParameter.where("connection_id=? and parameter_name=?", self.g_connection, 'port').limit(1).update_all(parameter_value: rdp_port)
          else # create
            GuacamoleConnectionParameter.create(connection_id: self.g_connection, parameter_name: 'port', parameter_value: rdp_port )
          end
          
        end #EOF connection check
        # check if the connection persist/has been created
        if self.g_connection
          # allow connection if none exists
          permission = GuacamoleConnectionPermission.where("user_id=? and connection_id=? and permission=?", self.lab_user.g_user, self.g_connection, 'READ').first
          unless permission # if no permission, create one
            result = GuacamoleConnectionPermission.create(user_id: self.lab_user.g_user, connection_id: self.g_connection, permission: 'READ')
            unless result
              return {success: false, message: 'unable to allow connection in guacamole'} 
            end
          end
          # log in 
          post = Http.post(url_prefix + "/api/tokens", {username: self.lab_user.g_username, password:self.lab_user.g_password})
          if post.body && post.body['authToken']
            # get machine url
            uri = GuacamoleConnection.get_url(self.g_connection)
            path = url_prefix + "/#/client/#{uri}"
            { success: true, url: path, token: post.body, domain: cookie_domain}
          else
            {success: false, message: 'unable to log in'}
          end
        else
          { success: false, message: 'unable to get machine connection'}
        end
      else
        {success: false, message: 'this virtual machine does not allow this connection'}
      end
    else
      {success: false, message: 'please start this virtual machine before trying to establish a connection'}
    end
  end

end

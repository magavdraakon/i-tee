class Vm < ActiveRecord::Base
  belongs_to :user
  belongs_to :lab_vmt
  belongs_to :lab_user
  before_destroy :try_delete_vm
  before_create :create_password

  validates_presence_of :name, :lab_vmt_id, :lab_user_id
  validates_uniqueness_of :name

  def try_delete_vm
    begin
      self.delete_vm
    rescue
      # ignore failure
    end
  end

  def create_password
    self.password = SecureRandom.urlsafe_base64(ITee::Application::config.rdp_password_length)
  end

  def reset_rdp
    Virtualbox.reset_vm_rdp(name)
  end

  def vm_info
    unless self.instance_variable_defined?(:@vm_info)
      logger.debug "Loading VM info of '#{name}'"
      begin
        @vm_info = Virtualbox.get_vm_info(name, true)
      rescue Exception => e
        unless e.message == 'Not found'
          raise e
        end
        @vm_info = false
      end
    end
    @vm_info
  end

  def state
    if self.vm_info
      state = self.vm_info['VMState']
      unless state == 'running' or state == 'paused'
        state = 'stopped'
      end
    else
      state = 'stopped'
    end
    logger.debug "State of '#{name}' is '#{state}'"
    state
  end

  def rdp_port
    if self.vm_info
      rdp_port = self.vm_info['vrdeport'].to_i
      if rdp_port == -1
        rdp_port = 0
      end
    else
      rdp_port = 0
    end
    logger.debug "RDP port of '#{name}' is #{rdp_port}"
    rdp_port
  end

  def delete_vm
    begin
      Virtualbox.stop_vm(name)
    rescue
      # ignore failure
    end
    Virtualbox.delete_vm(name)
  end

  def stop_vm
    unless [ 'running', 'paused' ].include?(self.state)
      return
    end

    unless self.lab_vmt.allow_restart
      return
    end

    begin
      Virtualbox.stop_vm(name)
    rescue
      # ignore failure, Virtualbox model logs the message
    end

    self.description='Power on the virtual machine by clicking <strong>Start</strong>.'
    self.save
  end

  def start_vm

    if ['running', 'paused'].include?(self.state)
      raise 'Already running'
    end

    begin
      unless Virtualbox.all_machines.include? name

        logger.debug "Machine '#{name}' does not exist, creating from '#{self.lab_vmt.vmt.image}'"

        # Create new instance of template
        begin
          current_snapshot=Virtualbox.get_vm_info(self.lab_vmt.vmt.image)['CurrentSnapshotName']
          logger.debug "Cloning #{name} from slapshot '#{current_snapshot}'"
          Virtualbox.clone(self.lab_vmt.vmt.image, name, current_snapshot)
        rescue
          Virtualbox.clone(self.lab_vmt.vmt.image, name)
        end

        groupname,dummy,username = name.rpartition('-')

        Virtualbox.set_groups(name, [ "/#{groupname}", "/#{username}" ])
        Virtualbox.set_extra_data(name, "VBoxAuthSimple/users/#{username}", Digest::SHA256.hexdigest(password))
        Virtualbox.set_extra_data(name, "VBoxInternal/Devices/pcbios/0/Config/DmiBIOSVersion", name)
        Virtualbox.set_extra_data(name, "VBoxInternal/Devices/pcbios/0/Config/DmiBIOSReleaseDate", username)
        Virtualbox.set_extra_data(name, "VBoxInternal/Devices/pcbios/0/Config/DmiSystemProduct", Rails.configuration.application_url)
        Virtualbox.set_extra_data(name, "VBoxInternal/Devices/pcbios/0/Config/DmiSystemSKU", "System SKU")
        Virtualbox.set_extra_data(name, "VBoxInternal/Devices/pcbios/0/Config/DmiSystemFamily", "System Family")
        Virtualbox.set_extra_data(name, "VBoxInternal/Devices/pcbios/0/Config/DmiSystemVendor", "I-tee Distance Laboratory System")
        if self.lab_vmt.expose_uuid
          Virtualbox.set_extra_data(name, "VBoxInternal/Devices/pcbios/0/Config/DmiSystemVersion", self.lab_user.uuid)
        else
          Virtualbox.set_extra_data(name, "VBoxInternal/Devices/pcbios/0/Config/DmiSystemVersion", "System Version")
        end
        if !self.lab_user.lab.lab_hash.blank? and !self.lab_user.user.user_key.blank?
          Virtualbox.set_extra_data(name, "VBoxInternal/Devices/pcbios/0/Config/DmiSystemSerial", "#{self.lab_user.lab.lab_hash}/#{self.lab_user.user.user_key}")
        else
          Virtualbox.set_extra_data(name, "VBoxInternal/Devices/pcbios/0/Config/DmiSystemSerial", "System Serial")
        end
      end

      self.lab_vmt.lab_vmt_networks.each do |nw|
        # substituting placeholders with data
        network_name = nw.network.name.gsub('{year}', Time.now.year.to_s)
                      .gsub('{user}', self.lab_user.user.username)
                      .gsub('{slot}', nw.slot.to_s)
                      .gsub('{labVmt}', self.lab_vmt.name)
        logger.debug "Setting network: slot: #{nw.slot}; type: #{nw.network.net_type}; name: #{network_name}"
        Virtualbox.set_network(name, nw.slot, nw.network.net_type, network_name)
      end

      logger.debug "Starting machine"
      Virtualbox.start_vm(name)

      desc = 'To create a connection with this machine using linux/unix use<br/>'
      desc += '<srong>'+self.remote('rdesktop')+'</strong>'
      desc += '<br/> or use xfreerdp as<br/>'
      desc += '<srong>'+self.remote('xfreerdp')+'</strong>'
      desc += '<br/>To create a connection with this machine using Windows use two commands:<br/>'
      desc += '<srong>'+self.remote('win')+'</strong>' #"<strong>cmdkey /generic:#{rdp_host} /user:localhost\\#{self.lab_user.user.username} /pass:#{self.password}</strong><br/>"
      #desc += "<strong>mstsc.exe /v:#{rdp_host}:#{rdp_port_prefix}#{port} /f</strong><br/>"
      logger.debug "\n setting #{self.id} description to \n #{desc}"
      self.description = desc

      self.save

      self.lab_user.last_activity = Time.now
      self.lab_user.activity = "Start vm - '#{self.name}'"
      self.lab_user.save

    rescue Exception => e
      logger.error "Failed to start vm: #{e.message}"
      raise 'Failed to start vm'
    end
  end

  #pause a machine
  def pause_vm
    state = self.state
    if state == 'running'
      Virtualbox.pause_vm(name)
    elsif state == 'paused'
      raise 'Already paused'
    else
      raise 'Bad machine state: ' + state
    end
  end

  #resume machine from pause
  def resume_vm
    state = self.state
    if state == 'paused'
      Virtualbox.resume_vm(name)
    elsif state == 'running'
      raise 'Already running'
    else
      raise 'Bad machine state: ' + state
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
    info = { }
    info[:username] = self.lab_user.user.username
    info[:password] = self.password
    info[:host] = ITee::Application.config.rdp_host
    info[:port] = self.rdp_port
    info
  end

  def remote(type)
    rdp_host = ITee::Application.config.rdp_host
    case type
      when 'win'
        desc = "cmdkey /generic:#{rdp_host} /user:localhost&#92;#{self.lab_user.user.username} /pass:#{self.password}&amp;&amp;"
        desc += "mstsc.exe /v:#{rdp_host}:#{self.rdp_port} /f"
      when 'rdesktop'
        desc ="rdesktop  -u#{self.lab_user.user.username} -p#{self.password} -N -a16 #{rdp_host}:#{self.rdp_port}"
      when 'xfreerdp'
        desc ="xfreerdp  --plugin cliprdr -g 90% -u #{self.lab_user.user.username} -p #{self.password} #{rdp_host}:#{self.rdp_port}"
      when 'mac'
        desc ="open rdp://#{self.lab_user.user.username}:#{self.password}@#{rdp_host}:#{self.rdp_port}"
      else
        desc ="rdesktop  -u#{self.lab_user.user.username} -p#{self.psassword} -N -a16 #{rdp_host}:#{self.rdp_port}"
    end
  end

  def open_guacamole
    # check if vm has guacamole enabled
    if self.state=='running'
      if self.lab_vmt.allow_remote and self.lab_vmt.g_type != ''


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
            protocol: self.lab_vmt.g_type,
            max_connections: max_connections, 
            max_connections_per_user: max_user_connections )
          
          if result
            result.add_parameters([
              { parameter_name: 'hostname', parameter_value: rdp_host },
              { parameter_name: 'port', parameter_value: self.rdp_port },
              { parameter_name: 'username', parameter_value: self.lab_user.user.username },
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

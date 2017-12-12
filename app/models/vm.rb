class Vm < ActiveRecord::Base
  belongs_to :user
  belongs_to :lab_vmt
  belongs_to :lab_user
  before_destroy :try_delete_vm
  before_create :create_password

  validates_presence_of :name, :lab_vmt_id, :lab_user_id
  validates_uniqueness_of :name

  def try_delete_vm
    do_delete = true
    begin
      info = Virtualbox.get_vm_info(self.name, true)
    rescue Exception => e
      unless e.message == 'Not found'
        raise e
      end
      do_delete = false
    end
    # only if vbox has the machine description
    if do_delete
      logger.debug "before destroy for #{self.name} will try to stop & delete the vm"
      begin
        self.delete_vm
        logger.info "#{self.name} stopped and deleted"
      rescue Exception => e 
        raise e
      end
    end
  end

  def create_password
    self.password = SecureRandom.urlsafe_base64(ITee::Application::config.rdp_password_length)
  end

  def reset_rdp
    begin
      Virtualbox.reset_vm_rdp(name)
      {success: true, message: "Vm rdp reset successful"}
    rescue
      {success: true, message: "Vm rdp reset failed"}
    end
  end

  def vm_info
    logger.debug "Loading VM info of '#{name}'"
    begin
      return Virtualbox.get_vm_info(name, true)
    rescue Exception => e
      unless e.message == 'Not found'
        raise e
      end
      return false
    end
  end

  def state
    info = self.vm_info
    if info
      state = info['VMState']
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
    info = self.vm_info
    if info
      rdp_port = info['vrdeport'].to_i
      if rdp_port == -1
        rdp_port = 0
      end
    else
      rdp_port = 0
    end
    logger.debug "RDP port of '#{name}' is #{rdp_port}"
    rdp_port
  end

# check if vbox knows this vm, stop if needed, but always delete
  def delete_vm
    begin
      info = Virtualbox.get_vm_info(self.name, true)
      state = info['VMState']
      if state=='running' || state=='paused'
        Virtualbox.stop_vm(name)
        logger.debug "#{self.name} VM stopped"
      end
      Virtualbox.delete_vm(name)
      logger.debug "#{self.name} VM deleted"
    rescue Exception => e
      if e.message == 'Not found'
        logger.debug "VM #{self.name} not found"
        return true # if machine does not exist, it is deleted
      else
        logger.error e
        raise "Deleting VM #{self.name} failed"
      end
    end
  end

  def stop_vm
    state = self.state
    if state=='running' || state=='paused'
      if self.lab_vmt.allow_restart
        begin
          Virtualbox.stop_vm(name)
          self.description = 'Power on the virtual machine by clicking <strong>Start</strong>.'
          self.save
          {success: true, message: "#{self.lab_vmt.nickname} successfully shut down"}
        rescue
          # ignore failure, Virtualbox model logs the message
          {success: false, message: "Failed to stop machine #{self.lab_vmt.nickname}"}
        end       
      else
        {success: true, message: "Machine #{self.lab_vmt.nickname} can not be shut down"}
      end
    else
      {success: true, message: "Machine #{self.lab_vmt.nickname} was already shut down"}
    end
  end

  def start_vm

    result = {notice: '', alert: ''}

    state = self.state
    if state == 'running' || state == 'paused'
      result[:alert]="Unable to start <b>#{self.lab_vmt.nickname}</b>, it is already running"
      return result
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
      logger.debug "\n save successful "

      result[:notice] = "Machine <b>#{self.lab_vmt.nickname}</b> successfully started<br/>"

      self.lab_user.last_activity = Time.now
      self.lab_user.activity = "Start vm - '#{self.name}'"
      self.lab_user.save

    rescue Exception => e
      logger.error "Failed to start vm: #{e.message}"
      result[:notice] = ''
      result[:alert]="Machine <b>#{self.lab_vmt.nickname}</b> initialization <b>failed</b>."
    end

    result
  end


  #pause a machine
  def pause_vm
    state = self.state
    if state=='running'
      logger.info 'running VM pause script'
      Virtualbox.pause_vm(name)
      {success: true, message: 'Successful vm pause.'}
    elsif state=='paused'
      {success: false, message:'Unable to pause a paused machine'}
    else
      {success: false, message: 'unable to pause a shut down machine'}
    end
  end

  #resume machine from pause
  def resume_vm
    state = self.state
    if state=='paused'
      logger.info 'running VM resume script'
      Virtualbox.resume_vm(name)
      {success: true, message: 'Successful vm resume.'}
    elsif state=='running'
      {success: false, message:'Unable to resume a running machine'}
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
    info = { }
    info[:username] = self.lab_user.user.username
    info[:password] = self.password
    info[:host] = ITee::Application.config.rdp_host
    info[:port] = self.rdp_port
    info
  end

  # connection informations
  def remote(typ, resolution='')
    if resolution!="" 
      logger.debug "\n resolution is #{resolution}"
    end

    rdp_host=ITee::Application.config.rdp_host

    case typ
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

  # TODO: remove race conditions
  def open_guacamole
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

	begin
          guacamole_user = GuacamoleUser.find(self.lab_user.g_user)
	rescue ActiveRecord::RecordNotFound => e
          self.lab_user.g_username = user_prefix+"#{self.lab_user.id}"
          self.lab_user.g_password = SecureRandom.base64
          guacamole_user = GuacamoleUser.create!(username: self.lab_user.g_username, password_hash: self.lab_user.g_password, timezone: 'Etc/GMT+0')
          self.lab_user.g_user = guacamole_user.user_id
          self.lab_user.save!
	end

        begin
          guacamole_connection = GuacamoleConnection.find(self.g_connection)
          begin
            port_parameter = GuacamoleConnectionParameter.find([ guacamole_connection, 'port' ])
            port_parameter.parameter_value = rdp_port
            port_parameter.save!
          rescue ActiveRecord::RecordNotFound => e
            GuacamoleConnectionParameter.create!(connection_id: guacamole_connection.connection_id, parameter_name: 'port', parameter_value: rdp_port)
          end
        rescue ActiveRecord::RecordNotFound => e
          guacamole_connection = GuacamoleConnection.create!( connection_name: user_prefix+self.name,
            protocol: self.lab_vmt.g_type,
            max_connections: max_connections, 
            max_connections_per_user: max_user_connections )
          
          guacamole_connection.add_parameters([
            { parameter_name: 'hostname', parameter_value: rdp_host },
            { parameter_name: 'port', parameter_value: self.rdp_port },
            { parameter_name: 'username', parameter_value: self.lab_user.user.username },
            { parameter_name: 'password', parameter_value: self.password },
#           { parameter_name: 'color-depth', parameter_value: 255 }
          ])

          self.g_connection = guacamole_connection.connection_id
          self.save!
        end

        begin
          GuacamoleConnectionPermission.create!(user_id: guacamole_user.user_id, connection_id: guacamole_connection.connection_id, permission: 'READ')
        rescue ActiveRecord::RecordNotUnique => e
          # Ignored intentionally
        end

        post = HttpRequest.post(url_prefix + "/api/tokens", {username: self.lab_user.g_username, password: self.lab_user.g_password})
        if post.body && post.body['authToken']
          uri = GuacamoleConnection.get_url(self.g_connection)
          path = url_prefix + "/#/client/#{uri}"
          { success: true, url: path, token: post.body, domain: cookie_domain }
        else
          {success: false, message: 'unable to log in'}
        end

      else
        {success: false, message: 'this virtual machine does not allow this connection'}
      end
    else
      {success: false, message: 'please start this virtual machine before trying to establish a connection'}
    end
  end

  def manage_network(action, nw)
    data = Virtualbox.get_vm_info(self.name)
    data.each do |key, value|
      unless ['nic','macaddress','cableconnected', 'intnet', 'natnet', 'hostonlyadapter', 'bridgeadapter'].any? { |word| key.include?(word) }
        data.delete(key) 
      end
    end
    case action.downcase 
    when 'get'
      return  JSON.pretty_generate(data)
    when 'post'
      if nw.blank? || nw[:slot].blank? || nw[:type].blank? || nw[:name].blank?
        return {success: false, message: "not enough info to add a network : slot, type, name"}
      end
      allowed = ['null', 'nat','intnet', 'bridgeadapter', 'hostonlyadapter']
      unless allowed.include?(nw[:type])
        return {success: false, message: "network type not supported", allowed: allowed}
      end
      Virtualbox.set_running_network(self.name, nw[:slot], nw[:type], nw[:name])
      return {success: true, message: "added network to #{self.name}", network: nw}
    when 'delete'
      if nw.blank?
        return {success: false, message: "not enough info to remove a network : slot or name"}
      end
      if nw[:slot].blank?
        if nw[:name].blank?
          return {success: false, message: "not enough info to remove a network : slot or name"}
        else
          field = ''
          data.each do |key, value|
            if value==nw[:name]
              field = key
            end
          end
          if field.blank?
            return {success: false, message: "the machine #{self.name} does not have a network with the name: #{nw[:name]}"}
          else
            nw[:slot] = field.gsub(/[^0-9]/, '')
          end
        end
      end

      Virtualbox.set_running_network(self.name, nw[:slot], 'null', '')
      return {success: true, message: "removed network from #{self.name}", network: nw}
    end
  end

end

require 'digest'

class Vm < ActiveRecord::Base
  
  belongs_to :lab_vmt
  belongs_to :lab_user
  before_destroy :try_delete_vm
  before_create :create_password

  validates_presence_of :name, :lab_vmt_id, :lab_user_id
  validates_uniqueness_of :name

  # compile vm and labuser info for log
  def log_info
    "vm=#{self.id} [#{self.name}] #{self.lab_user ? self.lab_user.log_info : 'labuser=[not found]'}"
  end

  def try_delete_vm
    loginfo = self.log_info.to_s
    logger.debug "VM BEFORE_DESTROY CALLED: #{loginfo}" 
    do_delete = true
    begin
      info = Virtualbox.get_vm_info(self.name, true)
    rescue Exception => e
      unless e.message == 'Not found'
        raise e
      end
      logger.debug "VM ALREADY DELETED: #{loginfo}"
      do_delete = false
    end
    # only if vbox has the machine description
    if do_delete
      logger.debug "Will try to stop & delete the vm '#{self.name}'"
      begin
        self.delete_vm
        logger.info "VM STOPPED & DELETED: #{loginfo}"
      rescue Exception => e 
        raise e
      end
    end
  end

  def create_password
    self.password = SecureRandom.urlsafe_base64(ITee::Application::config.rdp_password_length)
  end

  def reset_rdp
    loginfo = self.log_info.to_s
    logger.debug "VM RESET RDP CALLED: #{loginfo}"
    begin
      Virtualbox.reset_vm_rdp(name)
       logger.debug "VM RESET RDP SUCCESS: #{loginfo}"
      {success: true, message: "Vm rdp reset successful"}
    rescue
      logger.error "VM RESET RDP FAILED: #{loginfo}"
      {success: true, message: "Vm rdp reset failed"}
    end
  end

  def vm_info
    loginfo = self.log_info.to_s
    logger.debug "VM INFO CALLED: #{loginfo}"
    begin
      return Virtualbox.get_vm_info(name, true)
    rescue Exception => e
      unless e.message == 'Not found'
        raise e
      end
      logger.debug "VM NOT FOUND: in Virtualbox #{loginfo}"
      return false
    end
  end

  def state(info=nil)
    loginfo = self.log_info.to_s
    logger.debug "VM STATE CALLED: #{loginfo}"
    info = self.vm_info if info.blank?
    if info
      state = info['VMState']
      unless state == 'running' or state == 'paused'
        state = 'stopped'
      end
    else
      state = 'stopped'
    end
    logger.debug "VM STATE: '#{state}' #{loginfo}"
    state
  end

  def rdp_port(info=nil)
    loginfo = self.log_info.to_s
    logger.debug "VM RDP PORT CALLED: #{loginfo}"
    info = self.vm_info if info.blank?
    if info
      rdp_port = info['vrdeport'].to_i
      if rdp_port == -1
        rdp_port = 0
      end
    else
      rdp_port = 0
    end
    logger.debug "VM RDP PORT: #{rdp_port} #{loginfo}"
    rdp_port
  end

# check if vbox knows this vm, stop if needed, but always delete
  def delete_vm
    loginfo = self.log_info.to_s
    logger.info "DELETE_VM CALLED: #{loginfo}"
    begin
      do_stop = true
      (0..5).each do |try|
        begin
          if do_stop # try to stop machine until machine is stopped state
            info = Virtualbox.get_vm_info(self.name, true)
            state = info['VMState']
            if state=='running' || state=='paused'
              logger.debug "DELETE_VM: stopping machine try=#{try} #{loginfo}"
              Virtualbox.stop_vm(name)
              logger.debug "DELETE_VM: stopped vm try=#{try} #{loginfo}"
              sleep 1 # wait a bit 
              do_stop = false
            end
          end
          logger.debug "DELETE_VM: deleting machine try=#{try} #{loginfo}"
          Virtualbox.delete_vm(name)
          logger.info "DELETE_VM SUCCESS: try=#{try} #{loginfo}"
          return true
        rescue Exception => e
          if e.message == 'Not found'
            logger.debug "DELETE_VM SUCCESS: already deleted try=#{try} #{loginfo}"
            return true # if machine does not exist, it is deleted
          else
            logger.error e
            info = Virtualbox.get_vm_info(self.name, true)
            state = info['VMState']
            logger.info "DELETE_VM: an error was caught try=#{try} state=#{state} #{loginfo}"
            if try < 5
              sleep 1
              next  # go to next loop if not last
            end
            raise e.message # raise error again
          end
        end # end rescue
      end # end loop
    rescue Exception => e
      if e.message == 'Not found'
        logger.debug "DELETE_VM SUCCESS: already deleted #{loginfo}"
        return true # if machine does not exist, it is deleted
      else
        logger.error e
        info = Virtualbox.get_vm_info(self.name, true)
        state = info['VMState']
        logger.error "DELETE_VM FAILED: state=#{state} #{loginfo}"
      end
    end
  end

  def stop_vm(info=nil)
    loginfo = self.log_info.to_s
    logger.info "STOP_VM CALLED: #{loginfo}"
    state = self.state(info)
    if state=='running' || state=='paused'
      if self.lab_vmt.allow_restart
        begin
          Virtualbox.stop_vm(name)
          self.description = 'Power on the virtual machine by clicking <strong>Start</strong>.'
          self.save
          logger.info "STOP_VM SUCCESS: #{loginfo}"
          {success: true, message: "#{self.lab_vmt.nickname} successfully shut down"}
        rescue Exception => e
          logger.error "STOP_VM FAILED: #{loginfo}"
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

  def start_vm(info=nil)
    loginfo = self.log_info.to_s
    logger.info "START_VM CALLED: #{loginfo}"
    result = {notice: '', alert: ''}
    state = self.state(info)
    if state == 'running' || state == 'paused'
      logger.info "START_VM: already running #{loginfo}"
      result[:alert]="Unable to start <b>#{self.lab_vmt.nickname}</b>, it is already running"
      return result
    end

    begin
      unless Virtualbox.all_machines.include? name

        image = self.lab_vmt.vmt.image
        logger.debug "START_VM: Machine does not exist, creating from vmt=#{image} #{loginfo}"
        Virtualbox.clone(image, name) # will return true or raise an error caught below

        logger.debug "START_VM: Configuring machine #{loginfo}"
        groupname,dummy,username = name.rpartition('-')

        Virtualbox.set_groups(name, [ "/#{groupname}", "/#{username}" ])
        Virtualbox.set_extra_data(name, "VBoxAuthSimple/users/#{username}", Digest::SHA256.hexdigest(password))
        Virtualbox.set_extra_data(name, "VBoxInternal/Devices/pcbios/0/Config/DmiBIOSVersion", name)
        Virtualbox.set_extra_data(name, "VBoxInternal/Devices/pcbios/0/Config/DmiBIOSReleaseDate", username)
        Virtualbox.set_extra_data(name, "VBoxInternal/Devices/pcbios/0/Config/DmiSystemProduct", Rails.configuration.application_url)
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
      ips = []
      self.lab_vmt.lab_vmt_networks.each do |nw|
        # substituting placeholders with data
        network_name = nw.network.name.gsub('{year}', Time.now.year.to_s)
                      .gsub('{user}', self.lab_user.user.username)
                      .gsub('{slot}', nw.slot.to_s)
                      .gsub('{labVmt}', self.lab_vmt.name)
        logger.info "START_VM: set newtwork slot=#{nw.slot} type=#{nw.network.net_type} name=#{network_name} #{loginfo}"
        Virtualbox.set_network(name, nw.slot, nw.network.net_type, network_name) # will return true or raise an error
        # add to a list of network-ip pairs if ip is set
        ips << "#{nw.slot}=#{nw.ip}" unless nw.ip.blank?
      end
      # add list of pre-determined ips if there are any
      unless ips.blank?
        joined = ips.join('|')
        logger.debug "START_VM: Setting ip addresses: #{joined} #{loginfo}"
        Virtualbox.set_extra_data(name, "VBoxInternal/Devices/pcbios/0/Config/DmiSystemSKU", joined)
      else
        Virtualbox.set_extra_data(name, "VBoxInternal/Devices/pcbios/0/Config/DmiSystemSKU", "System SKU")
      end

      # set all admin user passwords
      users = User.where(role: 2) # admin
      users.each do |user|
        logger.debug "START_VM: setting #{user.username}-admin password #{loginfo}"
        hash = Digest::SHA256.hexdigest(user.rdp_password)
        begin
          Virtualbox.set_extra_data(name, "VBoxAuthSimple/users/#{user.username}-admin", hash);
        rescue Exception => e
          logger.error "START_VM: Failed to set RDP password #{loginfo}: #{e.message}"
        end
      end

      logger.debug "START_VM: Starting machine #{loginfo}"
      Virtualbox.start_vm(name)

      username = self.lab_user.user.username
      password = self.password 
      rdp_port = self.rdp_port 

      desc = 'To create a connection with this machine using linux/unix use<br/>'
      desc += '<srong>'+self.remote('rdesktop','', username, password, rdp_port)+'</strong>'
      desc += '<br/> or use xfreerdp as<br/>'
      desc += '<srong>'+self.remote('xfreerdp','', username, password, rdp_port)+'</strong>'
      desc += '<br/>To create a connection with this machine using Windows use two commands:<br/>'
      desc += '<srong>'+self.remote('win','', username, password, rdp_port)+'</strong>' #"<strong>cmdkey /generic:#{rdp_host} /user:localhost\\#{self.lab_user.user.username} /pass:#{self.password}</strong><br/>"
      #desc += "<strong>mstsc.exe /v:#{rdp_host}:#{rdp_port_prefix}#{port} /f</strong><br/>"
      logger.debug "START_VM: setting description to #{desc} #{loginfo}"
      self.description = desc

      self.save
      logger.info "START_VM SUCCESS: #{loginfo}"

      result[:notice] = "Machine <b>#{self.lab_vmt.nickname}</b> successfully started<br/>"

      self.lab_user.last_activity = Time.now
      self.lab_user.activity = "Start vm - '#{self.name}'"
      self.lab_user.save

    rescue Exception => e
      logger.error "START_VM FAILED: #{e.message} #{loginfo}"
      result[:notice] = ''
      result[:alert]="Machine <b>#{self.lab_vmt.nickname}</b> initialization <b>failed</b>."
    end

    result
  end


  #pause a machine
  def pause_vm
    loginfo = self.log_info.to_s
    logger.info "PAUSE_VM CALLED: #{loginfo}"
    state = self.state
    if state=='running'
      logger.debug "PAUSE_VM: pausing machine #{loginfo}"
      Virtualbox.pause_vm(name)
      {success: true, message: 'Successful vm pause.'}
    elsif state=='paused'
      logger.debug "PAUSE_VM: already paused #{loginfo}"
      {success: false, message:'Unable to pause a paused machine'}
    else
      logger.debug "PAUSE_VM: vm not running #{loginfo}"
      {success: false, message: 'unable to pause a shut down machine'}
    end
  end

  #resume machine from pause
  def resume_vm
    loginfo = self.log_info.to_s
    logger.info "RESUME_VM CALLED: #{loginfo}"
    state = self.state
    if state=='paused'
      logger.debug "RESUME_VM: resuming vm #{loginfo}"
      Virtualbox.resume_vm(name)
      {success: true, message: 'Successful vm resume.'}
    elsif state=='running'
      logger.debug "RESUME_VM: already running #{loginfo}"
      {success: false, message:'Unable to resume a running machine'}
    else
      logger.debug "RESUME_VM: machine stopped #{loginfo}"
      {success: false, message: 'unable to resume a shut down machine'}
    end
  end


  def get_all_rdp(info=nil)
    info = self.vm_info if info.blank?
    username = self.lab_user.user.username
    password = self.password 
    rdp_port = self.rdp_port(info)
    [
      {os: ['Windows'], program: '', rdpline: self.remote('win','', username, password, rdp_port) },
      {os: ['Linux', 'UNIX'], program: 'xfreerdp', rdpline: self.remote('xfreerdp','', username, password, rdp_port) },
      {os: ['Linux', 'UNIX'], program: 'rdesktop', rdpline: self.remote('rdesktop','', username, password, rdp_port) },
      {os: ['MacOS'], program: '', rdpline: self.remote('mac','', username, password, rdp_port) }
    ]
  end

  def get_connection_info(info=nil)
    info = self.vm_info if info.blank?
    data = { }
    data[:username] = self.lab_user.user.username
    data[:password] = self.password
    data[:host] = ITee::Application.config.rdp_host
    data[:port] = self.rdp_port(info)
    data
  end

  # connection informations
  def remote(typ, resolution='', username=nil, password=nil, rdp_port=nil)
=begin
    unless resolution.blank?
      logger.debug "resolution is #{resolution}"
    end
=end
    rdp_host = ITee::Application.config.rdp_host
    username = self.lab_user.user.username if username.blank?
    password = self.password if password.blank?
    rdp_port = self.rdp_port if rdp_port.blank?

    case typ
      when 'win'
        desc = "cmdkey /generic:#{rdp_host} /user:localhost&#92;#{username} /pass:#{password}&amp;&amp;"
        desc += "mstsc.exe /v:#{rdp_host}:#{rdp_port} /f"
      when 'rdesktop'
        desc ="rdesktop  -u#{username} -p#{password} -N -a16 #{rdp_host}:#{rdp_port}"
      when 'xfreerdp'
        desc ="xfreerdp  --plugin cliprdr -g 90% -u #{username} -p #{password} #{rdp_host}:#{rdp_port}"
      when 'mac'
        desc ="open rdp://#{username}:#{password}@#{rdp_host}:#{rdp_port}"
      else
        desc ="rdesktop  -u#{username} -p#{password} -N -a16 #{rdp_host}:#{rdp_port}"
    end

  end

  # TODO: remove race conditions
  def open_guacamole
    loginfo = self.log_info.to_s
    logger.info "OPEN_GUCAMOlE CALLED: #{loginfo}"

    info = self.vm_info || {'VMState': 'stopped', 'vrdeport': 0}
    rdpPort = self.rdp_port(info)

    if self.state(info)=='running'
      if self.lab_vmt.allow_remote 
        if self.lab_vmt.g_type == 'GuacV2'
          # new guacamole link generation logic
          path = ''
          key = ITee::Application::config.shared_key
          logger.debug "KEY: #{key}"
          plaintext = "{\"uuid\": \"#{self.lab_user.uuid}\" ,\"machine\": \"#{self.name}\"}"
          logger.debug "PLAINTEXT: #{plaintext}"
          derived = Digest::SHA256.digest(key)
          logger.debug "DERIVED: #{derived}"
          # TODO: FINALIZE the new guacamolelink generation

          { success: true, url: path}
        elsif self.lab_vmt.g_type != 'none'
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

  	    
            guacamole_user = GuacamoleUser.where(username: user_prefix+"#{self.lab_user.id}").first
          if guacamole_user
            guacamole_user.password_hash = self.lab_user.g_password
            guacamole_user.apply_salt
            guacamole_user.save!
  	       else
            self.lab_user.g_username = user_prefix+"#{self.lab_user.id}"
            self.lab_user.g_password = SecureRandom.base64
            guacamole_user = GuacamoleUser.create!(username: self.lab_user.g_username, password_hash: self.lab_user.g_password, timezone: 'Etc/GMT+0')
            self.lab_user.g_user = guacamole_user.user_id
            self.lab_user.save!
  	       end

          begin
            guacamole_connection = GuacamoleConnection.find(self.g_connection)
            begin
              port_parameter = GuacamoleConnectionParameter.where(connection_id: guacamole_connection.id, parameter_name: 'port' ).first
              port_parameter.parameter_value = rdpPort
              port_parameter.save!
            rescue ActiveRecord::RecordNotFound => e
              GuacamoleConnectionParameter.create!(connection_id: guacamole_connection.connection_id, parameter_name: 'port', parameter_value: rdpPort)
            end
          rescue ActiveRecord::RecordNotFound => e
            guacamole_connection = GuacamoleConnection.create!( connection_name: user_prefix+self.name,
              protocol: self.lab_vmt.g_type,
              max_connections: max_connections, 
              max_connections_per_user: max_user_connections )
            
            guacamole_connection.add_parameters([
              { parameter_name: 'hostname', parameter_value: rdp_host },
              { parameter_name: 'port', parameter_value: rdpPort },
              { parameter_name: 'username', parameter_value: self.lab_user.user.username },
              { parameter_name: 'password', parameter_value: self.password },
  #           { parameter_name: 'color-depth', parameter_value: 255 }
            ])

            self.g_connection = guacamole_connection.connection_id
            self.save!
          end

          begin
            # allow connection if none exists
            permission = GuacamoleConnectionPermission.where("user_id=? and connection_id=? and permission=?", guacamole_user.user_id, guacamole_connection.connection_id , 'READ').first
            unless permission # if no permission, create one
              result = GuacamoleConnectionPermission.create(user_id: guacamole_user.user_id, connection_id: guacamole_connection.connection_id, permission: 'READ')
              unless result
                return {success: false, message: 'unable to allow connection in guacamole'} 
              end
            end

            # GuacamoleConnectionPermission.create!(user_id: guacamole_user.user_id, connection_id: guacamole_connection.connection_id, permission: 'READ')
          rescue ActiveRecord::RecordNotUnique => e
            # Ignored intentionally
          end

          post = HttpRequest.post(url_prefix + "/api/tokens", {username: self.lab_user.g_username, password: self.lab_user.g_password})
          logger.debug post
          logger.debug post.body if post.body
          if post.body && post.body['authToken']
            uri = GuacamoleConnection.get_url(self.g_connection)
            path = url_prefix + "/#/client/#{uri}"
            logger.info "OPEN_GUCAMOlE SUCCESS: #{loginfo}"
            { success: true, url: path, token: post.body, domain: cookie_domain }
          else
            logger.error "OPEN_GUCAMOlE FAILED: unable to log in #{loginfo}"
            {success: false, message: 'unable to log in'}
          end
        else
          logger.info "OPEN_GUCAMOlE FAILED: not allowed #{loginfo}"
          {success: false, message: 'this virtual machine does not allow this connection'}
        end
      else
        logger.info "OPEN_GUCAMOlE FAILED: not allowed #{loginfo}"
        {success: false, message: 'this virtual machine does not allow this connection'}
      end
    else
      logger.info "OPEN_GUCAMOlE FAILED: vm not running #{loginfo}"
      {success: false, message: 'please start this virtual machine before trying to establish a connection'}
    end
  end

  def manage_network(action, nw)
    loginfo = self.log_info.to_s
    logger.info "MANAGE_NETWORK CALLED: #{loginfo}"
    data = Virtualbox.get_vm_info(self.name)
    data.each do |key, value|
      unless ['nic','macaddress','cableconnected', 'intnet', 'natnet', 'hostonlyadapter', 'bridgeadapter'].any? { |word| key.include?(word) }
        data.delete(key) 
      end
    end
    case action.downcase 
    when 'get'
      logger.debug "MANAGE_NETWORK: got info #{loginfo}"
      return  JSON.pretty_generate(data)
    when 'post'
      if nw.blank? || nw[:slot].blank? || nw[:type].blank? || nw[:name].blank?
        logger.debug "MANAGE_NETWORK ADD FAILED: not enough info #{loginfo}"
        return {success: false, message: "not enough info to add a network : slot, type, name"}
      end
      allowed = ['null', 'nat','intnet', 'bridgeadapter', 'hostonlyadapter']
      unless allowed.include?(nw[:type])
        logger.debug "MANAGE_NETWORK ADD FAILED: network type not allowed #{loginfo}"
        return {success: false, message: "network type not supported", allowed: allowed}
      end
      logger.debug "MANAGE_NETWORK ADD: set network for running machine #{loginfo}"
      Virtualbox.set_running_network(self.name, nw[:slot], nw[:type], nw[:name])
      logger.debug "MANAGE_NETWORK ADD SUCCESS: #{loginfo}"
      return {success: true, message: "added network to #{self.name}", network: nw}
    when 'delete'
      if nw.blank?
        logger.debug "MANAGE_NETWORK DELETE FAILED: network not specified #{loginfo}"
        return {success: false, message: "not enough info to remove a network : slot or name"}
      end
      if nw[:slot].blank?
        if nw[:name].blank?
          logger.debug "MANAGE_NETWORK DELETE FAILED: network name not specified #{loginfo}"
          return {success: false, message: "not enough info to remove a network : slot or name"}
        else
          field = ''
          data.each do |key, value|
            if value==nw[:name]
              field = key
            end
          end
          if field.blank?
            logger.debug "MANAGE_NETWORK DELETE FAILED: network #{nw[:name]} not found #{loginfo}"
            return {success: false, message: "the machine #{self.name} does not have a network with the name: #{nw[:name]}"}
          else
            nw[:slot] = field.gsub(/[^0-9]/, '')
          end
        end
      end
      logger.debug "MANAGE_NETWORK DELETE: unset network for running machine #{loginfo}"
      Virtualbox.set_running_network(self.name, nw[:slot], 'null', '')
      logger.debug "MANAGE_NETWORK DELETE SUCCESS: #{loginfo}"
      return {success: true, message: "removed network from #{self.name}", network: nw}
    end
  end

end

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
    begin
      Virtualbox.reset_vm_rdp(name)
      {success: true, message: "Vm rdp reset successful"}
    rescue
      {success: true, message: "Vm rdp reset failed"}
    end
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
    state = self.state
    if state=='running' || state=='paused'
      if self.lab_vmt.allow_restart
        begin
          Virtualbox.stop_vm(name)
        rescue
          # ignore failure, Virtualbox model logs the message
        end

        self.description='Power on the virtual machine by clicking <strong>Start</strong>.'
        self.save

        {success: true, message: 'Successful macine shutdown'}
      else
        {success: true, message: 'Machine can not be shut down'}
      end
    else
      {success: true, message: 'Machine was already shut down'}
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

  def self.open_guacamole(vm, user)
     unless self.lab_vmt.allow_remote && self.lab_vmt.guacamole_type != 'none'
       raise 'Remote access is not allowed'
     end

     begin
       chost = ITee::Application::config.guacamole[:rdp_host]
     rescue
       logger.warn "RDP host for Guacamole not specified"
       chost = ITee::Application::config.rdp_host
     end

     cipher = OpenSSL::Cipher.new('aes-256-gcm');
     cipher.encrypt
     cipher.key = ITee::Application::config.guacamole[:initializer_key]
     iv = cipher.iv = cipher.random_iv
     encrypted = cipher.update(JSON.generate({
       :name => self.name,
       :type => self.lab_vmt.guacamole_type,
       :hostname => chost,
       :port => self.rdp_port,
       :username => self.user.username,
       :password => self.password,
       :"guacamole-username" => "lu#{self.lab_user.id}"
     })) + cipher.final
     tag = cipher.auth_tag

     message = Base64.strict_encode64(iv + tag + encrypted);

    return ITee::Application::config.guacamole[:initializer_url] + '/' + message;
  end

end

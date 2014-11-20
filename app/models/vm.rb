class Vm < ActiveRecord::Base
  has_one :mac
  belongs_to :user
  belongs_to :lab_vmt
  before_destroy :del_vm
  before_destroy :rel_mac
  before_create :add_pw
  
  validates_presence_of :name, :lab_vmt_id, :user_id
  validates_uniqueness_of :name
  def rel_mac
    mac=Mac.find(:first, :conditions=>["vm_id=?", id])
    if mac!=nil
      mac.vm_id=nil
      mac.save
    end
  end

  def add_pw
    chars = "abcdefghjkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789"
    self.password = ""
    8.times { |i| self.password << chars[rand(chars.length)] }
  end

  def del_vm
    return %x(sudo -u vbox #{Rails.root}/utils/delete_machine.sh #{name}  2>&1)
  end
  
  def poweroff_vm
    #TODO script .. pooleli
    return %x(sudo -u vbox #{Rails.root}/utils/stop_machine.sh #{name}  2>&1)
  end
  
  def poweron_vm
    #TODO script .. pooleli
    return %x(sudo -u vbox #{Rails.root}/utils/poweron_machine.sh #{name}  2>&1)
  end
  
  def res_vm
    return %x(sudo -u vbox #{Rails.root}/utils/resume_machine.sh #{name}  2>&1)
  end
  
  def pau_vm
    return %x(sudo -u vbox #{Rails.root}/utils/pause_machine.sh #{name}  2>&1)
  end
  
  def ini_vm
    return %x(sudo -u vbox #{Rails.root}/utils/start_machine.sh #{mac.mac} #{mac.ip} #{lab_vmt.vmt.image} #{name} #{password} 2>&1)
  end
  
  def state
    #TODO - state is libvirt specific
    #retunr values are running, paused, 
    #return %x(virsh -c qemu:///system domstate #{name} 2>&1).split(' ').first.rstrip
    #state  powered off, running, paused
    ret = %x[sudo -u vbox /usr/bin/VBoxManage showvminfo #{name}|grep -E '^State:']
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
    logger.info "Running VM power off script"
    a=self.poweroff_vm #the script is called in the model
    logger.info a
    self.description="Power on the virtual machine by clicking <strong>Start</strong>."
    self.save
    # remove link to  mac 
    @mac = Mac.find(:first, :conditions=>["vm_id=?", self.id])
    @mac.vm_id=nil
    @mac.save
    return "Successful shutdown" 
  end

  def start_vm
    #find out if there is a mac address bound with this vm already
    result = {notice: "", alert: ""}
    @mac= Mac.find(:first, :conditions=>["vm_id=?", self.id])
    # binding a unused mac address with the vm if there is no mac
    if @mac==nil then
      @mac= Mac.find(:first, :conditions=>["vm_id is null"])
      @mac.vm_id=self.id
      if @mac.save  #save successful
        result[:notice] = result[:notice]+"successful mac assignement."
      end #end -if save
    else
      #the vm had a mac already, dont do anything
      result[:notice] = result[:notice]+"Vm already had a mac."
    end # end if nil
      
    if self.state!="running" && self.state!="paused"
      logger.info "running Machine start script"
      # logging network interface info
      self.lab_vmt.lab_vmt_networks.each do |nw|
        # substituting placeholders with data
        gen_name=nw.network.name.gsub('{year}', Time.now.year.to_s)
        gen_name= gen_name.gsub('{user}', self.user.username)
        gen_name= gen_name.gsub('{slot}', nw.slot.to_s)
        gen_name= gen_name.gsub('{labVmt}', self.lab_vmt.name)

        logger.debug "\nNIC#{nw.slot} #{gen_name} \n"
      end

      @a=self.ini_vm #the script is called in the model
      
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
      desc =  "To create a connection with this machine using Windows use two commands:<br/>"
      desc += "<strong>cmdkey /generic:#{rdp_host} /user:#{self.user.username} /pass:#{self.password}</strong><br/>"
      desc += "<strong>mstsc.exe /v:#{rdp_host}:#{rdp_port_prefix}#{port} /f</strong><br/>"
      self.description="To create a connection with this machine using linux/unix use<br/><strong>rdesktop -k et -u#{self.user.username} -p#{self.password} -N -a16 #{rdp_host}:#{rdp_port_prefix}#{port}</strong></br> or use xfreerdp as</br><strong>xfreerdp  -k et --plugin cliprdr -g 90% -u #{self.user.username} -p #{self.password} #{rdp_host}:#{rdp_port_prefix}#{port}</strong></br>"
      self.description += desc

      self.save
       
      require 'timeout'
      status = Timeout::timeout(60) {
        # Something that should be interrupted if it takes too much time...
        if @a!=nil
          until @a.include?("masin #{self.name} loodud")
          #do nothing, just wait
            sleep(5)
            logger.debug "\nwaiting ...\n"
          end
        end
      }

      if @a.include?("masin #{self.name} loodud")
        result[:notice] = result[:notice]+"<br/>"+self.description
        #flash[:notice]=flash[:notice].html_safe
      else
        logger.info @a  
        @mac.vm_id=nil
        @mac.save
        result[:notice] = nil
        result[:alert]="Machine initialization <strong>failed</strong>."
      end
     # logger.debug "\n#{result}\n"
      
    end
    return result   
    # removed mac address conflict rescue. Conflict management is TODO!
  end


  #pause a machine
  def pause_vm
    logger.info "running VM pause script"
    a = self.pau_vm #the script is called in the model
    logger.info a
    return "Successful vm pause.<br/> To resume the machine click on the resume link next to the machine name."
  end

  #resume machine from pause
  def resume_vm
    logger.info "running VM resume script"
    a=self.res_vm # the script is called in the model
    logger.info a
    return "Successful vm resume." 
  end

end

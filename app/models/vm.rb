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
    return %x(/var/www/railsapps/i-tee/utils/stop_machine.sh #{name}  2>&1)
  end
  
  def res_vm
    return %x(/var/www/railsapps/i-tee/utils/resume_machine.sh #{name}  2>&1)
  end
  
  def pau_vm
    return %x(/var/www/railsapps/i-tee/utils/pause_machine.sh #{name}  2>&1)
  end
  
  def ini_vm
    return %x(sudo -u vbox /var/www/railsapps/i-tee/utils/start_machine.sh #{mac.mac} #{mac.ip} #{lab_vmt.vmt.image} #{name} #{password} 2>&1)
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
    when 'powered off'
      return 'stopped'
    else
      return 'stopped'
    end
  end

end

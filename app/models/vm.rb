class Vm < ActiveRecord::Base
  has_one :mac
  belongs_to :user
  belongs_to :lab_vmt
  before_destroy :del_vm
  before_destroy :rel_mac
  
  validates_presence_of :name, :lab_vmt_id, :user_id
  
  def rel_mac
    mac=Mac.find(:first, :conditions=>["vm_id=?", id])
    if mac!=nil
      mac.vm_id=nil
      mac.save
    end
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
    return %x(/var/www/railsapps/i-tee/utils/start_machine.sh #{mac.mac} #{lab_vmt.vmt.image} #{name} 2>&1)
  end
  
  def state
    return %x(virsh -c qemu:///system domstate #{name} 2>&1).rstrip
  end
end

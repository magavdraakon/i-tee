class Vm < ActiveRecord::Base
  has_one :mac
  belongs_to :user
  belongs_to :lab_vmt
  before_destroy :delete_vms

  def del_vm
    logger.info "käivitame masina sulgemise skripti"
      a=%x(/var/www/railsapps/i-tee/utils/stop_machine.sh #{name}  2>&1)
      logger.info a
      flash[:notice] = "Successful vm deletion." 
      @mac= Mac.find(:first, :conditions=>["vm_id=?", id])
      @mac.vm_id=nil
      @mac.save
  end
  
end

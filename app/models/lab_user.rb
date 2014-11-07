class LabUser < ActiveRecord::Base
  belongs_to :user
  belongs_to :lab
  
  validates_presence_of :user_id, :lab_id

# get all vms that belong to this labuser (Lab attempt)
  def vms
  	vmts=LabVmt.where("lab_id = ? ", self.lab_id)
  	Vm.where("user_id=? and lab_vmt_id in (?)", self.user_id, vmts)
  end
# to be displayed as vm info for labs that are not running
  def vmts
  	LabVmt.where("lab_id = ? ", self.lab_id)
  end

# create needed Vm-s based on the lab templates and set start to now
  def start_lab
  	self.vmts.each do |template|
        #is there a machine like that already?
        vm = Vm.where("lab_vmt_id=? and user_id=?", template.id, self.user.id).first
        if vm==nil then #no there is not
          Vm.create(:name=>"#{template.name}-#{self.user.username}", :lab_vmt=>template, :user=>self.user, :description=>"Initialize the virtual machine by clicking <strong>Start</strong>.")
          logger.debug "Machine #{template.name}-#{self.user.username} successfully generated."
        end
    end #end of making vms based of templates
    # set new start time
    self.start=Time.now
    self.save
  end

# remove all Vm-s and set the end to now
  def end_lab
  	self.vms.each do |vm|
        vm.destroy
        logger.debug "Machine #{vm.name} successfully deleted."
      end
      #end of deleting vms for this lab
    self.end=Time.now
    self.save 
  end

end

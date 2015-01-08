class LabUser < ActiveRecord::Base
  belongs_to :user
  belongs_to :lab
  
  validates_presence_of :user_id, :lab_id

	before_destroy :end_lab
# get all vms that belong to this labuser (Lab attempt)
  def vms
  	vmts=LabVmt.where("lab_id = ? ", self.lab_id)
  	Vm.where("user_id=? and lab_vmt_id in (?)", self.user_id, vmts)
  end

  def vm_statistic
  	running=0
  	stopped=0
  	paused=0
  	self.vms.each do |v|
  		if v.state=='running'
      		running+=1
    	elsif v.state=='paused'
      		paused+=1
    	elsif v.state=='powered'
      		stopped+=1
    	else
      		stopped+=1
    	end
  	end
  	info={'running'=>running, 'paused'=>paused, 'stopped'=>stopped}
  end

# to be displayed as vm info for labs that are not running
  def vmts
  	LabVmt.where("lab_id = ? ", self.lab_id)
  end

# create needed Vm-s based on the lab templates and set start to now
  def start_lab
  	if !self.start && !self.end  # can only start labs that are not started or finished
  		self.vmts.each do |template|
        	#is there a machine like that already?
        	vm = Vm.where("lab_vmt_id=? and user_id=?", template.id, self.user.id).first
        	if vm==nil  #no there is not
          		Vm.create(:name=>"#{template.name}-#{self.user.username}", :lab_vmt=>template, :user=>self.user, :description=>"Initialize the virtual machine by clicking <strong>Start</strong>.")
          		logger.debug "Machine #{template.name}-#{self.user.username} successfully generated."
        	end
    	end #end of making vms based of templates
    	# set new start time
    	self.start=Time.now
    	self.save
	end
  end

# remove all Vm-s and set the end to now
  def end_lab
  	if self.start && !self.end then # can only end labs that are started and not ended 
  		self.vms.each do |vm|
        	vm.destroy
       		logger.debug "Machine #{vm.name} successfully deleted."
      	end
      	#end of deleting vms for this lab
    	self.end=Time.now
    	self.save 
	end
  end

  def restart_lab
  	self.end_lab # end lab
  	self.start=nil
  	self.pause=nil
  	self.end=nil
  	self.progress=nil
  	self.result=nil
  	self.save
  	self.start_lab # start lab
  end

end

class LabUser < ActiveRecord::Base
  belongs_to :user
  belongs_to :lab
  has_many :vms
  
  validates_presence_of :user_id, :lab_id

	before_destroy :end_lab

# OLD: get all vms that belong to this labuser (Lab attempt)
  def vms_manual
    #find templates for lab
  	vmts=LabVmt.where('lab_id = ? ', self.lab_id)
    #find vms for user in lab
  	Vm.where('user_id=? and lab_vmt_id in (?)', self.user_id, vmts)
  end

  def vms_info
    # id, nickname, state, allow_remote, position, rdp lines
    vms = Vm.joins(:lab_vmt).where('lab_vmts.lab_id=? and vms.user_id=?', self.lab_id, self.user_id).order('position asc')
    result= []
    vms.each do |vm|
      result << {
        vm_id: vm.id,
        nickname: vm.lab_vmt.nickname,
        state: vm.state,
        allow_remote: vm.lab_vmt.allow_remote,
        guacamole_type: vm.lab_vmt.guacamole_type,
        position: vm.lab_vmt.position,
        primary: vm.lab_vmt.primary,
        vm_rdp: vm.get_all_rdp,
        connection: vm.get_connection_info
      }
    end
    result
  end

  def vms_view
    Vm.joins(:lab_vmt).where('lab_vmts.lab_id=? and vms.user_id=?', self.lab_id, self.user_id).order('position asc')
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
  	info={:running=>running, :paused=>paused, :stopped=>stopped}
  end

# to be displayed as vm info for labs that are not running
  def vmts
  	LabVmt.where('lab_id = ? ', self.lab_id)
  end

# create needed Vm-s based on the lab templates and set start to now
  def start_lab
  	unless self.start || self.end  # can only start labs that are not started or finished
  		self.vmts.each do |template|
        #is there a machine like that already?
        vm = Vm.where('lab_vmt_id=? and lab_user_id=?', template.id, self.id).first
        if vm==nil  #no there is not
         		vm = Vm.create(:name=>"#{template.name}-#{self.user.username}", :lab_vmt=>template, :user=>self.user, :description=> 'Initialize the virtual machine by clicking <strong>Start</strong>.', :lab_user=>self)

         		logger.debug "\n #{vm.lab_user.id} Machine #{vm.id} - #{template.name}-#{self.user.username} successfully generated.\n"
        end  

    	end #end of making vms based of templates
      # start delayed jobs for keeping up with the last activity
      LabUser.rdp_status(self.id)
    	# set new start time
    	self.start=Time.now
      self.last_activity=Time.now
      self.activity='Lab start'
    	self.save
      logger.debug "\n all machines\n"
      logger.debug self.vms.as_json
      logger.debug "\n -end- \n"
			if self.lab.startAll
				self.start_all_vms
			end
		end
  end

# remove all Vm-s and set the end to now
  def end_lab
  	if self.start && !self.end  # can only end labs that are started and not ended
  		Vm.destroy_all(lab_user_id: self)
      #self.destroy_all_vms
      #end of deleting vms for this lab

    	self.end=Time.now
    	self.save 
      # remove pending delayed jobs
      Delayed::Job.where('queue=?', "labuser-#{self.id}").destroy_all
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


	def start_all_vms
    # olny if lab is started
    if self.start && !self.end 
  		feedback =''
      success = true
  		self.vms.each do |vm|
  			if vm.state!='running' && vm.state!='paused'  # cant be running nor paused
  				start = vm.start_vm
  				logger.info "#{vm.name} (#{vm.lab_vmt.nickname}) started"
  				add = start[:notice]!='' ? start[:notice] : (start[:alert]!='' ? start[:alert] : "<b>#{vm.lab_vmt.nickname}</b> was not started")
  				feedback = feedback + add +'<br/>'
          unless add.include?('successfully started')
            success=false # one machine fails = all fails
          end
  			end #end if not running or paused
  		end
  		logger.info "\nfeedback: #{feedback}\n"
  		{ success: success, message: feedback}
    else
      { success: false, message: 'unable to start machines in inactive lab'}
    end
	end

	def stop_all_vms # TODO: should check if lab is started?
		feedback=''
		self.vms.each do |vm|
			if vm.state=='running' || vm.state=='paused'  # has to be running or paused
				stop = vm.stop_vm
				logger.info "#{vm.name} (#{vm.lab_vmt.nickname}) stopped"
				feedback=feedback+"<b>#{vm.lab_vmt.nickname}</b> stopped<br/>"
			end #end if not running or paused
		end
    # if no feedbck then no macines were stopped
		{success: feedback!='' , message:feedback}
	end

	def destroy_all_vms
		self.vms.each do |vm|
			vm.destroy
      if vm.destroyed? 
        logger.debug "\nMachine #{vm.id} - #{vm.name} successfully deleted.\n"
      else
        logger.debug "\nMachine #{vm.id} - #{vm.name} NOT deleted.\n"
      end
		end
	end


  def self.rdp_status(id)
    # vms exist only for running labs 
    labuser = LabUser.find_by_id(id)
    if labuser==nil 
      # do nothing if there is no vm
    else
      # get lab
      lab = labuser.lab
      if lab && lab.poll_freq>0 && !labuser.end # poll until labuser ends
        # iterate over vms for this lab
        labuser.vms.each do |vm|
          # check if rdp is allowed for user
          logger.debug "\n#{vm.name} found"
          if vm.lab_vmt.allow_remote 
            info = Virtualbox.get_vm_info(vm.name, true)
            if info 
              if info['VRDEActiveConnection']
                if info['VRDEActiveConnection']=="on"
                  labuser.last_activity=Time.now
                  labuser.activity = "RDP active - '#{vm.name}'"
                  logger.debug "RDP is active - #{vm.name}"
                end
              end # has field about rdp connection
            end # got vm info

          else # rdp is not enabled
            # do nothing
          end
        end # end foreach vms

        labuser.save
      
        # run this again in x seconds
        logger.debug "\nDO THIS AGAIN!\n"
        LabUser.delay(queue: "labuser-#{labuser.id}" ,run_at: lab.poll_freq.seconds.from_now ).rdp_status(labuser.id)
      end #lab exsist and has polling
    end # labuser exists
  end



end

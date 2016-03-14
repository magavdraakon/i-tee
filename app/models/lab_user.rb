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
        position: vm.lab_vmt.position,
        vm_rdp: vm.get_all_rdp
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
          		vm = Vm.create(:name=>"#{template.name}-#{self.user.username}", :lab_vmt=>template, :user=>self.user, :description=> 'Initialize the virtual machine by clicking <strong>Start</strong>.', :lab_user_id=>self.id)
          		logger.debug "Machine #{template.name}-#{self.user.username} successfully generated."
        	end    
    	end #end of making vms based of templates
      # start delayed jobs for keeping up with the last activity
      LabUser.rdp_status(self.id)
    	# set new start time
    	self.start=Time.now
      self.last_activity=Time.now
      self.activity='Lab start'
    	self.save
			if self.lab.startAll
				self.start_all_vms
			end
		end
  end

# remove all Vm-s and set the end to now
  def end_lab
  	if self.start && !self.end  # can only end labs that are started and not ended
  		self.destroy_all_vms
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
      logger.debug "Machine #{vm.name} successfully deleted."
			vm.destroy
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
      # iterate over vms for this lab
      labuser.vms.each do |vm|
        # check if rdp is allowed for user
        if vm.lab_vmt.allow_remote 
          
          info = %x(VBoxManage showvminfo #{vm.name})
          status= $?
          if status.exitstatus > 0
            logger.debug "Exit with error: #{status.exitstatus}"
            # machine not found / virtualbox error
          else
            #logger.debug info.split(/\n+/)
            virtual = {}
            info.split(/\n+/).each do |row|
              r=row.split(':', 2)
              if r[0] && r[1]
                virtual[ r[0] ]=r[1].strip
                #puts "#{r[0]} : #{r[1]}\n"
              end
            end
            
            # uninitialized machine - exit code 1, no vminfo
              #VBoxManage: error: Could not find a registered machine named 'webserver-Tiia'
              #VBoxManage: error: Details: code VBOX_E_OBJECT_NOT_FOUND (0x80bb0001), component VirtualBoxWrap, interface IVirtualBox, callee nsISupports
              #VBoxManage: error: Context: "FindMachine(Bstr(VMNameOrUuid).raw(), machine.asOutParam())" at line 2719 of file VBoxManageInfo.cpp
            # started machine, no rdp since init - 'Clients so far' == 0 && 'VRDE Connection'  == 'not active' && 'state' starts with 'running'
            # started machine, live rdp - 'VRDE Connection' == 'active' 'Clients so far' != 0 && 'Start time' && 'state' starts with 'running'
            # started machine, rdp closed - 'VRDE Connection'  == 'not active' && 'Last started' && 'Last ended' && 'state' starts with 'running'
            # stopped / paused machine - 'VRDE' contains 'enabled', no ^ fields! 'State' starts with 'powered off' / 'saved'

            # NB! if a machine is stopped and started again, 'Clients so far' starts from 0

            # if RDP is allowed
            if virtual['VRDE'].include?('enabled')
              # check state 
              case virtual['State'].split('(').first.strip
              when 'running'
                puts "MACHINE IS RUNNING - #{vm.name}"
                if virtual['VRDE Connection']=='not active' # no running RDP

                elsif virtual['VRDE Connection']=='active' # running RDP
                  labuser.last_activity=Time.now
                  labuser.activity = "RDP active - '#{vm.name}'"
                  puts "RDP is active - #{vm.name}"
                end
              when 'powered off'
                puts "MACHINE IS SHUT DOWN - #{vm.name}"
              when 'saved'
                puts "MACHINE IS PAUSED - #{vm.name}"
              else
                # do nothing
              end #case state
            else
              # TODO! what to do if rdp is disabled in vm itself?
            end # if rdp
          end # if statuscode 0
          
        else # rdp is not enabled
          # do nothing
        end
      end # end foreach vms

      labuser.save

      if lab.poll_freq>0 && !labuser.end # poll until labuser ends
        # run this again in x seconds
        logger.debug "\nDO THIS AGAIN!\n"
        LabUser.delay(queue: "labuser-#{labuser.id}" ,run_at: lab.poll_freq.seconds.from_now ).rdp_status(labuser.id)
      end
    end # labuser exists
  end



end

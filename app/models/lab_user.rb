class LabUser < ActiveRecord::Base
  belongs_to :user
  belongs_to :lab
  has_many :vms
  
  validates_presence_of :user_id, :lab_id

	before_destroy :end_lab

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
        allow_restart: vm.lab_vmt.allow_restart,
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

# create needed Vm-s based on the lab templates and set start to now
  def start_lab
  	unless self.start || self.end  # can only start labs that are not started or finished
      result = Check.has_free_resources
      if result && result[:success] # has resources
        LabVmt.where('lab_id = ? ', self.lab_id).each do |template|
          vm = Vm.where('lab_vmt_id=? and lab_user_id=?', template.id, self.id).first
          unless vm
            vm = Vm.create(:name=>"#{template.name}-#{self.user.username}", :lab_vmt=>template, :user=>self.user, :description=> 'Initialize the virtual machine by clicking <strong>Start</strong>.', :lab_user=>self)
            logger.debug "\n #{vm.lab_user.id} Machine #{vm.id} - #{template.name}-#{self.user.username} successfully generated.\n"
          end
        end
        # start delayed jobs for keeping up with the last activity
        LabUser.rdp_status(self.id)
      	# set new start time
      	self.start = Time.now
        self.last_activity = Time.now
        self.activity = 'Lab start'
        unless self.vta_setup # do not repeat setup if set by api
          # check if lab has assistant to be able to create the vta labuser
          lab = self.lab
          user = self.user
          if !lab.assistant_id.blank?
            assistant = lab.assistant
            password = SecureRandom.urlsafe_base64(16)
            rdp_host = ITee::Application.config.rdp_host
            result = assistant.create_labuser({"api_key": lab.lab_token , "lab": lab.lab_hash, "username": user.username, "fullname": user.name, "password": password,  "host": rdp_host , "info":{"somefield": "somevalue"}})
            if result && !result['key'].blank?
              # save to user
              user.user_key = result['key'];
              unless user.save
                return {success: false, message: 'unable to remember user token in assistant'}
              end
            else
              return {success: false, message: 'unable to communicate with assistant'}
            end
          end
        end
      	self.save
        logger.debug "\n all machines\n"
        logger.debug self.vms.as_json
        logger.debug "\n -end- \n"
  			if self.lab.startAll
  				self.start_all_vms
  			end
        {success: true, message: 'Lab started'}
      else
        result # forward the message from resource check
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
    self.end_lab
    self.vta_setup = false # assistant labuser needs to be reset
    self.start = nil
    self.pause = nil
    self.end = nil
    self.save
    self.start_lab
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
    labuser = LabUser.find_by_id(id)
    unless labuser
      return
    end

    lab = labuser.lab
    unless lab and lab.poll_freq > 0 and !labuser.end # poll until labuser ends
      return
    end

    labuser.vms.each do |vm|
      if vm.lab_vmt.allow_remote
        begin
          info = Virtualbox.get_vm_info(vm.name, true)
          if info['VRDEActiveConnection']=="on"
            labuser.last_activity=Time.now
            labuser.activity = "RDP active - '#{vm.name}'"
            logger.debug "RDP is active on '#{vm.name}'"
          end
        rescue
          # Ignore error, callee logs the error message
        end
      end
    end # end foreach vms

    labuser.save
      
    # run this again in x seconds
    LabUser.delay(queue: "labuser-#{labuser.id}", run_at: lab.poll_freq.seconds.from_now).rdp_status(labuser.id)
  end


 # get vta info from outside {host: 'http://', token: 'lab-specific update token', lab_hash: 'vta lab id', user_key: 'user token'}
  def set_vta(params)
    # find lab
    lab = self.lab
    user = self.user
    if lab
      if user
        # find assistant
        assistant = Assistant.where( uri: params['host'] ).first
        unless assistant # ensure existance
          assistant = Assistant.create(uri: params['host'])
        end
        # set assitant info on lab by force
        lab.assistant = assistant
        lab.lab_hash = params['lab_hash']
        lab.lab_token = params['token']
        if lab.save
          user.user_key = params['user_key']
          if user.save
            self.vta_setup = true # mark vta setup as done
            if self.save
              {success: true, message: 'Teaching assistant info set successfully'}
            else
              {success: true, message: 'Teaching assistant info set successfully but could not be marked as done'}
            end
          else
            {success: false, message: 'Could not save user mission info'}
          end
        else
          {success: false, message: 'Could not save mission info'}
        end
      else
        {success: false, message: 'Could not find user in host'}
      end
    else
      {success: false, message: 'Could not find mission in host'}
    end

  end

end

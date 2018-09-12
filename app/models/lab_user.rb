class LabUser < ActiveRecord::Base
  belongs_to :user
  belongs_to :lab
  has_many :vms
  has_many :labuser_connections, :dependent => :destroy
  
  validates_presence_of :user_id, :lab_id
  validates :uuid, :allow_nil => false, :allow_blank => false, :uniqueness => { :case_sensitive => false }
  validates :token, :allow_nil => false, :allow_blank => false, :uniqueness => { :case_sensitive => false }
  before_destroy :end_lab
  before_create :create_uuid

  # used in labuser index json format to include info on ping 
  def with_ping
    data = JSON.parse(self.to_json)
    if lab = JSON.parse(self.lab.to_json)
      data['treshold_low'] = lab['ping_low']
      data['treshold_mid'] = lab['ping_mid']
      data['treshold_high'] = lab['ping_high']
      data['ping_low'] = self.labuser_connections.where("end_at-start_at< ? ", lab['ping_low']).count
      data['ping_mid'] = self.labuser_connections.where("end_at-start_at between ? and ? ", lab['ping_low'], lab['ping_mid']).count     
      data['ping_high'] = self.labuser_connections.where("end_at-start_at between ? and ? ", lab['ping_mid'], lab['ping_high']).count
      data['ping_down'] = self.labuser_connections.where("end_at-start_at > ? ", lab['ping_high']).count
      peak = self.labuser_connections.order("end_at-start_at DESC").first
      data['ping_peak'] = peak.end_at-peak.start_at if peak
    end
    data
  end

  def vms_info
    # id, nickname, state, allow_remote, position, rdp lines
    vms = Vm.joins(:lab_vmt, :lab_user).where('lab_vmts.lab_id=? and vms.lab_user_id=lab_users.id and lab_users.user_id=?', self.lab_id, self.user_id).order('position asc')
    result= []
    vms.each do |vm|
      info = vm.vm_info || {'VMState': 'stopped', 'vrdeport': 0}
      result << {
        vm_id: vm.id,
        nickname: vm.lab_vmt.nickname,
        state: vm.state(info),
        expose_uuid: vm.lab_vmt.expose_uuid,
        allow_remote: vm.lab_vmt.allow_remote,
        allow_restart: vm.lab_vmt.allow_restart,
        guacamole_type: vm.lab_vmt.g_type,
        position: vm.lab_vmt.position,
        primary: vm.lab_vmt.primary,
        vm_rdp: vm.get_all_rdp(info),
        connection: vm.get_connection_info(info)
      }
    end
    result
  end

  def vms_view
    Vm.joins(:lab_vmt, :lab_user).where('lab_vmts.lab_id=? and vms.lab_user_id=lab_users.id and lab_users.user_id=?', self.lab_id, self.user_id).order('position asc')
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

  # info to include in event logging 
  def log_info
    "labuser=#{self.id} lab=#{self.lab_id } user=#{self.user_id} #{self.user ? '['+self.user.username+']' : ''}"
  end

# create needed Vm-s based on the lab templates and set start to now
  def start_lab
    lab = self.lab
    user = self.user
    loginfo = self.log_info.to_s
    logger.info "LAB START CALLED: #{loginfo}"
  	if self.start.blank? && self.end.blank?  # can only start labs that are not started or finished
      result = Check.has_free_resources
      if result && result[:success] # has resources
        LabVmt.where('lab_id = ? ', self.lab_id).each do |template|
          vm = self.vms.where(lab_vmt_id: template.id).first
          unless vm
            vm = self.vms.create!(:name=>"#{template.name}-#{self.user.username}", :lab_vmt=>template, :description=> 'Initialize the virtual machine by clicking <strong>Start</strong>.')
            logger.debug "#{vm.lab_user.id} Machine #{vm.id} - #{vm.name} successfully generated."
          end
        end
        logger.debug "LAB START: vms db entries created #{loginfo}"
        # start delayed jobs for keeping up with the last activity
        LabUser.rdp_status(self.id)
      	# set new start time
      	self.start = Time.now
        self.last_activity = Time.now
        self.activity = 'Lab start'
        unless self.vta_setup # do not repeat setup if set by api
          logger.debug "LAB START: begin VTA setup #{loginfo}"
          # check if lab has assistant to be able to create the vta labuser
          if !lab.assistant_id.blank?
            assistant = lab.assistant
            password = SecureRandom.urlsafe_base64(16)
            rdp_host = ITee::Application.config.rdp_host
            result = assistant.create_labuser({"api_key": lab.lab_token , "lab": lab.lab_hash, "username": user.username, "fullname": user.name, "password": password,  "host": rdp_host , "info":{"somefield": "somevalue"}})
            if result && !result['key'].blank?
              # save to user
              user.user_key = result['key'];
              unless user.save
                logger.error "LAB START FAILED: VTA setup failed - save failed #{loginfo}"
                return {success: false, message: 'unable to remember user token in assistant'}
              end
              logger.info "LAB START: VTA setup success #{loginfo}"
            else
              logger.error "LAB START FAILED: VTA setup failed - request error #{loginfo}"
              logger.error result
              return {success: false, message: 'unable to communicate with assistant'}
            end
          end
        end
      	self.save
        logger.debug "LAB START: VMS #{loginfo} \n #{self.vms.as_json}"

  			if self.lab.startAll
  				self.start_all_vms
  			end
        logger.info "LAB START SUCCESS: #{loginfo}"
        {success: true, message: 'Lab started'}
      else
        result # forward the message from resource check
      end
    elsif self.end # lab is ended
      logger.warn "LAB START FAILED: ended labuser #{loginfo}"
      {success: false, message: 'Ended mission can not be started'}
    else
      logger.warn "LAB START SUCCESS: lab already started #{loginfo}"
      {success: true, message: 'Lab started..'}
		end
  end

# remove all Vm-s and set the end to now
# called 2x in labuser_controller when removing lab from user
# called 3x in labs controller when ending lab (by id, by value, default)
# called during restart_lab
  def end_lab
    lab = self.lab
    user = self.user    
    loginfo = self.log_info.to_s
    logger.info "LAB END CALLED: #{loginfo}"
    if !self.start.blank? && self.end.blank?  # can only end labs that are started and not ended
      begin
        machines = Vm.where(lab_user_id: self.id) 
        # to make sure vms are being removed, do it one by one
        machines.each do |vm|
          vm.delete_vm
          logger.info "#{vm.name} stopped and deleted @ lab end"
        end
        # remove the db entries, the before destroy filter should realize there is no vm to destroy and will be 'skipped'
        machines.destroy_all
        logger.debug "VMS DELETED: #{loginfo}"
      rescue Exception => e
        logger.error e
        return {success: false, message: "Mission end failed" }
      end
      #self.destroy_all_vms
      #end of deleting vms for this lab
      self.uuid = SecureRandom.uuid
      self.token = SecureRandom.uuid # used by client
      self.end = Time.now
      if self.save
        logger.debug "REMOVE DELAYED JOBS: #{loginfo}"
        # remove pending delayed jobs
        Delayed::Job.where('queue=?', "labuser-#{self.id}").destroy_all
        return {success: true, message: "Mission ended" }
      else
        logger.error "LAB END FAILED: save failed #{loginfo}"
        return {success: false, message: "Unable to end this mission" }
      end
    elsif self.start.blank?
      return {success: false, message: "This mission has not been started" }
    else
      return {success: true, message: "This mission has already been ended" }
    end
  end

  def restart_lab    
    loginfo = self.log_info.to_s
    logger.info "LAB RESTART CALLED: #{loginfo}"
    self.end_lab
    self.vta_setup = false # assistant labuser needs to be reset
    self.start = nil
    self.pause = nil
    self.end = nil
    # destroy old ping info
    self.labuser_connections.destroy_all
    self.save
    self.start_lab
  end


	def start_all_vms
    lab = self.lab
    user = self.user    
    loginfo = self.log_info.to_s
    logger.info "START ALL VMS CALLED: #{loginfo}"
    # olny if lab is started
    if self.start && !self.end 
  		feedback =''
      success = true
  		self.vms.each do |vm|
        info = vm.vm_info || {'VMState': 'stopped', 'vrdeport': 0}
				start = vm.start_vm(info) 
        logger.debug start.as_json
        add = (start[:notice]!='' ? start[:notice] : (start[:alert]!='' ? start[:alert] : "<b>#{vm.lab_vmt.nickname}</b> was not started")	)
        feedback = feedback + add +'<br/>'
        unless add.include?('successfully started')
          logger.error "VM START FAILURE: vm=#{vm.id} [#{vm.name}] #{loginfo}"
          success = false # one machine fails = all fails
        else
          logger.info "VM START SUCCESS: vm=#{vm.id} [#{vm.name}] #{loginfo}"
        end
  		end
  		logger.info "START ALL VMS SUMMARY: #{loginfo} #{feedback}"
  		{ success: success, message: feedback}
    else
      logger.error "START ALL VMS FAILURE: lab not started #{loginfo}"
      { success: false, message: 'unable to start machines in inactive mission'}
    end
	end

	def stop_all_vms # TODO: should check if lab is started?
    lab = self.lab
    user = self.user
    loginfo = self.log_info.to_s
    logger.info "STOP ALL VMS CALLED: #{loginfo}"
		feedback=''
		self.vms.each do |vm|
      info = vm.vm_info || {'VMState': 'stopped', 'vrdeport': 0}
			if vm.state(info)=='running' || vm.state(info)=='paused'  # has to be running or paused
				stop = vm.stop_vm(info)
        if stop[:success]
  				logger.info "VM STOP SUCCESS: vm=#{vm.id} [#{vm.name}] #{loginfo}"
  				feedback = feedback+"<b>#{vm.lab_vmt.nickname}</b> stopped<br/>"
        else
          logger.error "VM STOP FAILURE: vm=#{vm.id} [#{vm.name}] #{loginfo}"
          feedback = feedback+"<b>#{vm.lab_vmt.nickname}</b> not stopped<br/>"
        end
			end #end if not running or paused
		end
    logger.info "STOP ALL VMS SUMMARY: #{loginfo} #{feedback}"
    # if no feedbck then no macines were stopped
		{success: feedback!='' , message:feedback}
	end

  # deprecated?
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


 # get vta info from outside {host: 'http://', name:"", version:"" token: 'lab-specific update token', lab_hash: 'vta lab id', user_key: 'user token'}
  def set_vta(params)
    # find lab
    lab = self.lab
    user = self.user
    loginfo = self.log_info.to_s
    logger.info "SET VTA INFO CALLED: #{loginfo}"
    if lab
      logger.debug 'found lab'
      if user
        logger.debug 'found user'
        # find assistant
        assistant = Assistant.where( uri: params['host'] ).first
        unless assistant # ensure existence
          logger.debug 'Create assistant'
          assistant = Assistant.create(uri: params['host'], name: params['name'], enabled: true, version: (params['version'] ? params['version'] : 'v1'))
        end
        if assistant
          # set assistant info on lab by force
          lab.assistant = assistant
          lab.lab_hash = params['lab_hash']
          lab.lab_token = params['token']
          if lab.save
            user.user_key = params['user_key']
            if user.save
              self.vta_setup = true # mark vta setup as done
              if self.save
                answer = {success: true, message: 'Teaching assistant info set successfully'}
              else
                answer = {success: true, message: 'Teaching assistant info set successfully but could not be marked as done'}
              end
            else
              answer = {success: false, message: 'Could not save user mission info'}
            end
          else
            answer = {success: false, message: 'Could not save mission info'}
          end
        else
          answer = {success: false, message: 'Could not describe assistant in host'}
        end
      else
        answer = {success: false, message: 'Could not find user in host'}
      end
    else
      answer = {success: false, message: 'Could not find mission in host'}
    end
    logger.debug answer
    if answer[:success]
      logger.info "SET VTA INFO SUCCESS: #{loginfo}"
    else
      logger.error "SET VTA INFO FAILED: #{loginfo}"
    end
    answer
  end

# create a temporary uuid when the labuser is created. this will be overwritten by lab end
def create_uuid
  self.uuid = SecureRandom.uuid
  self.token = SecureRandom.uuid # used by client
end

def self.add_users(params)
  lab = Lab.where(id: params[:lab_user][:lab_id]).first
  if lab
    User.where(id: params[:users]).each do |c|
      l = lab.lab_users.new
      l.user = c
      #if there is no db row with the set parameters then create one
      unless lab.lab_users.where(user_id: c.id).first
        l.save
        logger.debug "labuser created #{l.id}"
      end
    end
    # destroy all extra lab_users
    lab.lab_users.where.not(user_id: params[:users]).destroy_all
  end
end

end

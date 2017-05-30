class LabUser < ActiveRecord::Base
  belongs_to :user
  belongs_to :lab
  has_many :vms
  
  validates_presence_of :user_id, :lab_id
  validates :uuid, :allow_nil => false, :allow_blank => false, :uniqueness => { :case_sensitive => false }
  before_destroy :end_lab
  before_create :create_uuid

  def vms_info
    # id, nickname, state, allow_remote, position, rdp lines
    vms = Vm.joins(:lab_vmt, :lab_user).where('lab_vmts.lab_id=? and vms.lab_user_id=lab_users.id and lab_users.user_id=?', self.lab_id, self.user_id).order('position asc')
    result= []
    vms.each do |vm|
      result << {
        vm_id: vm.id,
        nickname: vm.lab_vmt.nickname,
        state: vm.state,
        expose_uuid: vm.lab_vmt.expose_uuid,
        allow_remote: vm.lab_vmt.allow_remote,
        allow_restart: vm.lab_vmt.allow_restart,
        guacamole_type: vm.lab_vmt.g_type,
        position: vm.lab_vmt.position,
        primary: vm.lab_vmt.primary,
        vm_rdp: vm.get_all_rdp,
        connection: vm.get_connection_info
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

  def start_lab
    unless self.start.blank? and self.end.blank?
      raise 'Invalid state'
    end

    unless self.vta_setup # do not repeat setup if set by api
      lab = self.lab
      if !lab.assistant_id.blank?
        user = self.user
        assistant = lab.assistant
        password = SecureRandom.urlsafe_base64(16)
        rdp_host = ITee::Application.config.rdp_host
        result = assistant.create_labuser({ "api_key": lab.lab_token, "lab": lab.lab_hash, "username": user.username, "fullname": user.name, "password": password, "host": rdp_host, "info": {} })
        if result && !result['key'].blank?
          user.user_key = result['key'];
          user.save!
        else
          raise 'Failed to communicate with assistant'
        end
      end
    end

    ActiveRecord::Base.transaction do
      LabVmt.where('lab_id = ? ', self.lab_id).each do |template|
        Vm.create(:name=>"#{template.name}-#{self.user.username}", :lab_vmt => template, :user => self.user, :description => 'Initialize the virtual machine by clicking <strong>Start</strong>.', :lab_user => self)
      end

      self.start = Time.now
      self.last_activity = Time.now
      self.activity = 'Lab start'

      self.save!
    end

    if self.lab.startAll
      self.start_all_vms
    end

    # start delayed jobs for keeping up with the last activity
    LabUser.rdp_status(self.id)
  end

  def end_lab
    if self.start && !self.end # Ignore if state is invalid
      Vm.destroy_all(:lab_user_id => self)
      self.uuid = SecureRandom.uuid
      self.end = Time.now
      self.save!
      Delayed::Job.where('queue=?', "labuser-#{self.id}").destroy_all
    end
  end

  def restart_lab
    self.end_lab
    self.vta_setup = false # assistant labuser needs to be reset
    self.start = nil
    self.pause = nil
    self.end = nil
    self.save!
    self.start_lab
  end


  def start_all_vms
    unless self.start and !self.end
      raise 'Invalid state'
    end

    feedback = {}
    self.vms.each do |vm|
      if [ 'running', 'paused' ].include?(vm.state)
        begin
          start = vm.start_vm
          logger.info "#{vm.name} (#{vm.lab_vmt.nickname}) started"
          feedback[vm.lab_vmt.nicname] = nil
        rescue Exception => e
          feedback[vm.lab_vmt.nickname] = e.message
        end
      end
    end
    feedback
  end

  def stop_all_vms
    # FIXME: should check if lab is started?
    feedback = {}
    self.vms.each do |vm|
      if [ 'running', 'paused' ].include?(vm.state)
        begin
          stop = vm.stop_vm
          logger.info "#{vm.name} (#{vm.lab_vmt.nickname}) stopped"
          feedback[vm.lab_vmt.nickname] = nil
        rescue Exception => e
          feedback[vm.lab_vmt.nickname] = e.message
        end
      end
    end
    feedback
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
    logger.debug "set VTA info for #{lab.as_json} #{user.as_json}"
    if lab
      logger.debug 'found lab'
      if user
        logger.debug 'found user'
        # find assistant
        assistant = Assistant.where( uri: params['host'] ).first
        unless assistant # ensure existance
          logger.debug 'Create assistant'
          assistant = Assistant.create(uri: params['host'], name: params['name'], enabled: true)
        end
        if assistant
          # set assitant info on lab by force
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
    answer
  end

# create a temporary uuid when the labuser is created. this will be overwritten by lab end
def create_uuid
  self.uuid = SecureRandom.uuid
end

end

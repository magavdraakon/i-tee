class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable, :lockable and :timeoutable
  devise :ldap_authenticatable, #:registerable,
         :rememberable, :trackable, :validatable

  # Setup accessible (or protected) attributes for your model
  attr_accessible :name, :username, :email, :password, :password_confirmation, :remember_me, :token_expires, :role

  has_many :vms#, :dependent => :destroy
  has_many :lab_users#, :dependent => :destroy 
  before_destroy :del_labs # vms are deleted trough lab user
  before_save :nilify_email
 # has_many :user_badges, :dependent => :destroy

  validates_format_of :username, :with => /^[[:alnum:]]+[[:alnum:]_]+[[:alnum:]]$/ , :message => 'can only be alphanumeric with and dashes with no spaces'

  def nilify_email
    if self.email == ''
      self.email = nil
    end
  end

  def email_required?
    false
  end

  def select_name
    "[#{id}] #{name}"
  end

  def del_labs
    logger.debug 'removing labs'
    self.lab_users.each do |lu|
      lu.destroy
    end
  end

  def rolename
    case self.role
    when 0
      'user'
    when 1
      'manager'
    when 2
      'admin'
    else
      'NaN'
    end
  end

  def is_admin?
     self.role==2 || ITee::Application.config.admins.include?(username)
  end

  def is_manager?
    self.role==1 || ITee::Application.config.managers.include?(username)
  end

  # find first user that has the given token
  def self.find_by_token(token)
    User.where('authentication_token=?', token).first
  end

  def reset_authentication_token!
    loop do
      token = Devise.friendly_token
      # FIXME: doesn't this cause potential concurrency issues?
      unless User.where(authentication_token: token).first
        self.authentication_token = token
        break
      end
    end
  end

  def has_badge(lab_badge_id)
    ub=UserBadge.where('lab_badge_id=? and user_id=?', lab_badge_id, id).all
    ub.count>0
  end

  def has_lab(lab_id)
    LabUser.where('user_id=? and lab_id=?', self.id, lab_id).count > 0 ? true : false
  end

  def set_rdp_password(password='')
    if password.size < 1
      logger.debug 'Generating new password'
      password = SecureRandom.urlsafe_base64(ITee::Application::config.rdp_password_length)
    end

    hash = Digest::SHA256.hexdigest(password)
    Virtualbox.all_machines.each do |vm|
      begin
        Virtualbox.set_extra_data(vm, "VBoxAuthSimple/users/#{self.username}", hash);
      rescue Exception => e
        logger.error "Failed to set RDP password for machine #{vm}: #{e.message}"
      end
    end

    self.rdp_password = password
    self.save
  end

  def unset_rdp_password
    Virtualbox.all_machines.each do |vm|
      begin
        Virtualbox.set_extra_data(vm, "VBoxAuthSimple/users/#{self.username}");
      rescue Exception => e
        logger.error "Failed to unset RDP password for machine #{vm}: #{e.message}"
      end
    end

    self.rdp_password = ''
    self.save
  end
end

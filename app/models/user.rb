class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable, :lockable and :timeoutable
  devise :ldap_authenticatable, #:registerable,
         :recoverable, :rememberable, :trackable, :validatable, :token_authenticatable

  # Setup accessible (or protected) attributes for your model
  attr_accessible :username, :email, :password, :password_confirmation, :remember_me, :keypair, :token_expires, :role

  has_many :vms, :dependent => :destroy
  has_many :lab_users, :dependent => :destroy
  has_many :user_badges, :dependent => :destroy

  validates_format_of :username, :with => /^[[:alnum:]]+[[:alnum:]_]+[[:alnum:]]$/ , :message => 'can only be alphanumeric with and dashes with no spaces'


  def rolename
    if self.role==nil
      'NaN'
    elsif self.role==0
      'user'
    elsif self.role==1
      'manager'
    elsif self.role==2
      'admin'
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
    User.where("authentication_token=?", token).first
  end

  def has_badge(lab_badge_id)
    ub=UserBadge.where("lab_badge_id=? and user_id=?", lab_badge_id, id).all
    ub.count>0
  end

  def has_lab(lab_id)
    LabUser.where("user_id=? and lab_id=?", self.id, lab_id).size > 0 ? true : false
  end
end

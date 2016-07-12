class Lab < ActiveRecord::Base
  
  #has_many :vms, :dependent => :destroy #get these trough lab_vmts?
  has_many :lab_vmts, :dependent => :destroy
  has_many :lab_users, :dependent => :destroy
  has_many :lab_badges, :dependent => :destroy
  belongs_to :host

  accepts_nested_attributes_for :lab_vmts, :reject_if =>  proc { |attributes| attributes['name'].blank? && attributes['vmt_id'].blank? }, :allow_destroy => true
  accepts_nested_attributes_for :lab_badges, :reject_if => :all_blank, :allow_destroy => true
  
  validates_presence_of :name, :short_description
  validates_uniqueness_of :name
#return all vms in this lab
  def vms
    lvs=[]
    self.lab_vmts.each do |l|
      lvs<<l.id
    end
    Vm.where('lab_vmt_id in (?)', lvs)
  end

# return list of users in this lab
  def users
  	ids=[]
  	self.lab_users.each do |lu|
  		ids << lu.user_id
  	end
  	User.where('id in (?)', ids)
  end

# add any user that doesnt have this lab yet
  def add_all_users
    logger.debug "\n adding all users to lab: '#{self.name}'\n"
  	User.all.each do |u|
      l=LabUser.new
      l.lab_id=self.id
      l.user_id=u.id
      l.save if LabUser.where('lab_id=? and user_id=?', l.lab_id, l.user_id).first==nil
    end
  end
  
# remove all users from this lab
  def remove_all_users
    logger.debug "\n removing all users from lab: '#{self.name}'\n"
  	self.lab_users.each do |u|
      u.destroy
    end
  end

end

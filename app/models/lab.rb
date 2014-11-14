class Lab < ActiveRecord::Base
  
  #has_many :vms, :dependent => :destroy #get these trough lab_vmts?
  has_many :lab_vmts, :dependent => :destroy
  has_many :lab_users, :dependent => :destroy
  has_many :lab_badges, :dependent => :destroy
  belongs_to :host
  
  validates_presence_of :name, :short_description

  def users
  	ids=[]
  	self.lab_users.each do |lu|
  		ids << lu.user_id
  	end
  	User.where("id in (?)", ids)
  end

# add any user that doesnt have this lab yet
  def add_all_users
  	User.all.each do |u|
      l=LabUser.new
      l.lab_id=self.id
      l.user_id=u.id
      l.save if LabUser.find(:first, :conditions=>["lab_id=? and user_id=?", l.lab_id, l.user_id])==nil
    end
  end
  
# remove all users from this lab
  def remove_all_users
  	self.lab_users.each do |u|
      u.destroy
    end
  end

end

class Lab < ActiveRecord::Base
  has_many :lab_materials, :dependent => :destroy
  #has_many :vms, :dependent => :destroy #get these trough lab_vmts?
  has_many :lab_vmts, :dependent => :destroy
  has_many :lab_users, :dependent => :destroy
  
  validates_presence_of :name
end

class Lab < ActiveRecord::Base
  has_many :lab_materials, :dependent => :destroy
  has_many :vms, :dependent => :destroy
end

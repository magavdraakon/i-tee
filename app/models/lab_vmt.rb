class LabVmt < ActiveRecord::Base
  belongs_to :lab
  belongs_to :vmt
  has_many :vms, :dependent => :destroy
  
  validates_presence_of :lab_id, :vmt_id, :name
  
   def menustr
    "#{name} - #{lab.name}"
  end
  
end

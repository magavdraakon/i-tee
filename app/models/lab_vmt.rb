class LabVmt < ActiveRecord::Base
  belongs_to :lab
  belongs_to :vmt
  has_many :vms, :dependent => :destroy
  
   def menustr
    "#{name} - #{lab.name}"
  end
  
end

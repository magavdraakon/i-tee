class LabUser < ActiveRecord::Base
  belongs_to :user
  belongs_to :lab
  
  validates_presence_of :user_id, :lab_id

# get all vms that belong to this labuser (Lab attempt)
  def vms
  	vmts=LabVmt.where("lab_id = ? ", self.lab_id)
  	Vm.where("user_id=? and lab_vmt_id in (?)", self.user_id, vmts)
  end
# to be displayed as vm info for labs that are not running
  def vmts
  	LabVmt.where("lab_id = ? ", self.lab_id)
  end
end

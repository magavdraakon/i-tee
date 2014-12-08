class Vmt < ActiveRecord::Base
  has_many :lab_vmts, :dependent => :destroy
  belongs_to :operating_system
  validates_presence_of :image, :username, :operating_system_id

  def available
    available=[]
    %x(vboxmanage list vms | grep template|cut -d' ' -f1|tr '"' ' ').split("\n").each do |vmt|
      available<< vmt.strip
    end
    available
  end
end

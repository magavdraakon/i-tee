class Vm < ActiveRecord::Base
  has_one :mac
  belongs_to :user
  belongs_to :lab_vmt

   attr_accessor :state
  
  def state=(val)
    @state=val
  end
  
  def state?
    if @state==nil
      "stopped"
    else
      @state
    end
  end
end

class Vmt < ActiveRecord::Base
  has_many :lab_vmts, :dependent => :destroy
  validates_presence_of :image, :username

  def available
    available=[]
    Virtualbox.template_machines.each do |vmt|
      available<< vmt.strip
    end
    Rails.logger.debug "Templated - #{available}"
    available
  end
end

class Vmt < ActiveRecord::Base
  has_many :lab_vmts, :dependent => :destroy
  validates_presence_of :image, :username

  if ITee::Application::config.respond_to? :cmd_perfix
    @exec_line = ITee::Application::config.cmd_perfix
  else
    @exec_line = 'sudo -Hu vbox '
  end


  def available
    available=[]
    %x(sudo -Hu vbox VBoxManage list vms | grep template|cut -d' ' -f1|tr '"' ' ').split("\n").each do |vmt|
      available<< vmt.strip
    end
    Rails.logger.debug "Templated - #{available}"
    available
  end
end

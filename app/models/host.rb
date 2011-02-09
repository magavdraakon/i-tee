class Host < ActiveRecord::Base
  #TODO! geteucainstance asendada get virtualisationinstance 
  #kontrollida configist kas kasutada libvirt-i või eucat
  
  
  
  def getEycalyptusInstance
    if ITee::Application.config.emulate_eucalyptus then
      return EmulateEucalyptus.new
    else
      #asendada euca libvirt-ga
      return Eucalyptus.new
    end
  end
  
  def getVirtInstance
    if ITee::Application.config.use_libvirt then
      return Libvirt.new
    else
      getEycalyptusInstance
    end
    
  end

end

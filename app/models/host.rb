class Host < ActiveRecord::Base

  def getEycalyptusInstance
    if ITee::Application.config.emulate_eucalyptus then
      return EmulateEycalyptus.new
    else
      return Eycalyptus.new
    end
  end

end

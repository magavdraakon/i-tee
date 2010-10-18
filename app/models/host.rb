class Host < ActiveRecord::Base

  def getEycalyptusInstance
    if ITee::Application.config.emulate_eucalyptus then
      return EmulateEucalyptus.new
    else
      return Eucalyptus.new
    end
  end

end

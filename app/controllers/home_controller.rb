class HomeController < ApplicationController
  layout 'main'
  
  def index
    @images = Host.new.getEycalyptusInstance.getImages
    @instances = Host.new.getEycalyptusInstance.getInstances
    @runningInstances = Host.new.getEycalyptusInstance.getRunningInstances    
  end

end

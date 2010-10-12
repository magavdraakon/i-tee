class HomeController < ApplicationController
  layout 'main'
  
  def index
    @images = Host.new.getEycalyptusInstance.getImages
  end

end

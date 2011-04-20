class HomeController < ApplicationController
   before_filter :authorise_as_admin, :only=>[:system_info, :template_info]
  
  def index
  end

  def error_401
    
  end
  
  def system_info
  end
  
  def template_info
  end
  
  def catcher
    flash[:notice] = 'Seems that the page you were looking for does not exist, so you\'ve been redirected here.'
    redirect_to :action => 'index'
  end

end

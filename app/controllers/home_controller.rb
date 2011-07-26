class HomeController < ApplicationController
   before_filter :authorise_as_admin, :only=>[:system_info, :template_info]
  before_filter :home_tab, :except=>[:about]
  def index
  end

  def error_401
    
  end
  
  def system_info
  end
  
  def about
    @tab="home" if user_signed_in?
  end
  
  def template_info
  end
  
  def catcher
    flash[:notice] = 'Seems that the page you were looking for does not exist, so you\'ve been redirected here.'
    redirect_to :action => 'index'
  end

end

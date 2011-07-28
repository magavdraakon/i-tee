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
  
  #this is a method that updates a lab_users progress
  #input parameters: ip (the machine, the report is about)
  #           progress (the progress for the machine)
  def getprogress
    render :layout => false
    #who sent the info?
    @client_ip = request.remote_ip
    @remote_ip = request.env["HTTP_X_FORWARDED_FOR"]
    
    #get the lab_user based on the ip aadress- get the vm with the given ip, get the vm-s lab_user
    # update the labuser.progress based on the input
    ip=params[:ip]
    progress=params[:progress]
    
  end
  
  def template_info
  end
  
  def catcher
    flash[:notice] = 'Seems that the page you were looking for does not exist, so you\'ve been redirected here.'
    redirect_to :action => 'index'
  end

end

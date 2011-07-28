class ApplicationController < ActionController::Base
  rescue_from DeviseLdapAuthenticatable::LdapException do |exception|
    render :text => exception, :status => 500
  end
  
  Time.zone='Tallinn'
  protect_from_forgery
  
  layout 'new'
  
  before_filter :check_for_cancel, :only => [:create, :update]

  if ITee::Application.config.emulate_ldap then
    before_filter :emulate_user
  else
    before_filter :authenticate_user!, :except=>[:about, :getprogress]
    before_filter :admin?
  end  
  
  def emulate_user
    @admin = true
    @logged_in = true
    @username = "ttanav"
    current_user.username=@username
    current_user.id=1
  end

  #return true if the current user is a admin
  def admin?
    if current_user == nil then
      @admin = false
      return
    end
    if  ITee::Application.config.admins.include?(current_user.username) then
      @admin = true
    else
      @admin = false
    end
  end
  

  
  #redirect user if they are not admin but try to see things not meant for them
  def authorise_as_admin
    unless ITee::Application.config.admins.include?(current_user.username)
      #You don't belong here. Go away.
     
      flash[:alert]  = "Restricted access!"
        redirect_to(:controller=>'home', :action=>'error_401')
      end
      
    end
  
  private#-------------------------------------------------------------------
      
      
      
  def home_tab
    @tab="home"
  end
      
  def course_tab
    @tab="courses"
  end
      
  def vm_tab
    @tab="vms"
  end
      
  def admin_tab
    @tab="admin"
  end

  def check_for_cancel
    if params[:commit] == "Cancel"
      redirect_to :action=>"index"
    end
  end
end

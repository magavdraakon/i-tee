class ApplicationController < ActionController::Base
  rescue_from DeviseLdapAuthenticatable::LdapException do |exception|
    render :text => exception, :status => 500
  end
  
  Time.zone='Tallinn'
  protect_from_forgery
  
  layout 'new'
  require 'will_paginate/array'
  before_filter :check_for_cancel, :only => [:create, :update]
  before_filter :check_token

  if ITee::Application.config.emulate_ldap then
     @admin = true
    @logged_in = true
    @username = "ttanav"
    #current_user = User.find(:first, :conditions=>["username=?", @username])
    current_user = User.first

    before_filter :emulate_user    
  else
    before_filter :authenticate_user!, :except=>[:about, :getprogress, :set_progress]
    before_filter :admin?
    before_filter :manager?
  end  
  
  def emulate_user
   
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
  
  def manager?
     if current_user == nil then
      @manager = false
      return
    end
    if  ITee::Application.config.managers.include?(current_user.username) then
      @manager = true
    else
      @manager = false
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
  
    #redirect user if they are not manager or admin but try to see things not meant for them
  def authorise_as_manager
    unless ITee::Application.config.managers.include?(current_user.username) || ITee::Application.config.admins.include?(current_user.username)
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
  
  def manager_tab
    @tab="manager"
  end

  def check_for_cancel
    if params[:commit] == "Cancel"
      redirect_to :action=>"index"
    end
  end
  
  def check_token
    if params[:auth_token]!=nil then
      # is tehre a token?
      user=User.find(:first, :conditions=>["authentication_token=?", params[:auth_token]])
      if user==nil then
        #there is no such user. we dont need to do anything, devise will do it for us
      else 
        expiretime=user.token_expires
        logger.debug "the user: #{expiretime.inspect}"
        logger.debug "the time: #{DateTime.now().inspect}"
        # check if the token is still valid 
        if expiretime.to_datetime < DateTime.now() then
          #the token has expired already, deny the user access
          
          redirect_to destroy_user_session_path
        end  
      end
    end
  end
  
end

class ApplicationController < ActionController::Base
  rescue_from DeviseLdapAuthenticatable::LdapException do |exception|
    render :text => exception, :status => 500
  end
  
  Time.zone='Tallinn'
  protect_from_forgery
  

  require 'will_paginate/array'
  before_filter :check_for_cancel, :only => [:create, :update]

  layout :set_layout

  before_filter :authenticate_user_from_token!
  before_filter :authenticate_user!, :except=>[:about, :getprogress, :set_progress, :labinfo]
  before_filter :admin?
  before_filter :manager?
  before_filter :per_page

  def set_layout
    logger.info('REQUEST: ' + request.host)
    begin
      if ITee::Application.config.skins.key?(request.host)
        return ITee::Application.config.skins[request.host]
      end
    rescue
    end

    logger.info('No skin set for this host, trying to get default skin')
    begin
      return ITee::Application.config.default_skin
    rescue
      logger.info('no default skin set in config, use EIK skin')
      return 'EIK'
    end
  end

  def per_page
    @per_page = ITee::Application.config.per_page
  end

  #return true if the current user is a admin
  def admin?
    # if there is no logged in user, there is no admin
    unless current_user
      @admin = false
      return
    end
    # check config to see if the user is an admin (true/false)
    @admin = current_user.is_admin?
  end
  

  def manager?
    # if there is no logged in user, there is no manager
    unless current_user
      @manager = false
      return
    end
    # check config to see if the user is a manager (true/false)
    @manager = current_user.is_manager?
  end

  
   # redirect user if they are not admin but try to see things not meant for them
  def authorise_as_admin
    unless @admin
      respond_to do |format|  #You don't belong here. Go away.
        flash[:alert]  = 'Restricted access!'
        #You don't belong here. Go away.
        format.html { redirect_to(:controller=>'home', :action=>'error_401') }
        format.json { render :json=> {:success => false , :message=> 'Restricted access!'} }
      end    
    end
  end
  
   # redirect user if they are not manager (or admin) but try to see things not meant for them
  def authorise_as_manager
    unless @manager || @admin
      respond_to do |format|  #You don't belong here. Go away.
        flash[:alert]  = 'Restricted access!'
        #You don't belong here. Go away.
        format.html { redirect_to(:controller=>'home', :action=>'error_401') }
        format.json { render :json=> {:success => false , :message=> 'Restricted access!'} }
      end      
    end
   end
  
  private#-------------------------------------------------------------------

  def set_order_by
    if params[:dir]=='desc'
      dir = 'DESC'
      @dir = 'asc'
    else
      dir = 'ASC'
      @dir = 'desc'
    end
    @order = params[:sort_by]!=nil ? "#{params[:sort_by]} #{dir}" : ''
  end
      
  def home_tab
    @tab='home'
  end
      
  def course_tab
    @tab='courses'
  end
      
  def vm_tab
    @tab='vms'
  end
      
  def admin_tab
    @tab='admin'
  end
  
  def manager_tab
    @tab='manager'
  end

  def user_tab

      @tab='user'

  end

  def search_tab
    @tab='search'
  end

  def virtualization_tab
    @tab='virtual'
  end

  def check_for_cancel
    if params[:commit] == 'Cancel'
      if params[:controller]=='vms'
        # special behaiviour because users cant edit their vms but they can see them
        redirect_to :action=>'index', :admin=>'1'
      else 
        redirect_to :action=>'index'
      end
    end
  end
  
  def authenticate_user_from_token!
    if params[:auth_token]
      # get the user with the given token
      user=User.where('authentication_token=?', params[:auth_token]).first
      # if there is such a user
      if user
        expiretime = user.token_expires
        logger.debug "the user: #{expiretime.inspect}"
        logger.debug "the time: #{DateTime.now.inspect}"
        # check if the token is still valid 
        if expiretime.to_datetime < DateTime.now
          #the token has expired already, deny the user access
          redirect_to destroy_user_session_path
        else
          sign_in user
        end
      end
    end
  end
  
end

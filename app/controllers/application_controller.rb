class ApplicationController < ActionController::Base
  rescue_from DeviseLdapAuthenticatable::LdapException do |exception|
    render :text => exception, :status => 500
  end
  
  protect_from_forgery
  if ITee::Application.config.emulate_ldap then
    before_filter :emulate_user
  else
    before_filter :authenticate_user!
    before_filter :admin?
  end
  
   layout 'main'
  
  def emulate_user
    @admin = true
    @logged_in = true
    @username = "Test User"
  end

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
  
  def authorise_as_admin
    unless ITee::Application.config.admins.include?(current_user.username)
      #You don't belong here. Go away.
      flash[:alert]  = "Restricted access!"
        redirect_to (:controller=>'home', :action=>'error_401')
      end
    end
  
end

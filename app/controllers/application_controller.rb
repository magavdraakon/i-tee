class ApplicationController < ActionController::Base
  rescue_from DeviseLdapAuthenticatable::LdapException do |exception|
    render :text => exception, :status => 500
  end
  protect_from_forgery
  if ITee::Application.config.fake_ldap then
    before_filter :fake_user
  else
    before_filter :authenticate_user!
    before_filter :admin?
  end
  
  
  def fake_user
    @admin=true
  end
  def admin?
    if current_user==nil then
      @admin=false
      return
    end
    if  ITee::Application.config.admins.include?(current_user.username) then
      @admin=true
    else
      @admin=false
    end
  end
  
end

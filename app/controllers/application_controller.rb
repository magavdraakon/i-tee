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
  
  def emulate_user
    @admin = true
    @logged_in = true
    @username = "Peeter Pakiraam"
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

  ## except bug || :new bug
  # http://dev.rubyonrails.org/ticket/8867
  # https://rails.lighthouseapp.com/projects/8994/tickets/5371-layout-with-onlyexcept-options-makes-other-actions-render-without-layouts
  # layout 'application', :except => :sign_in

  layout 'login', :only => [:sign_in, :sign_up]
  layout 'application', :only => [:index, :show, :edit, :new]
end

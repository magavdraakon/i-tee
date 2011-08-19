class Users::RegistrationsController < Devise::RegistrationsController
  before_filter :redirect_root, :only => [:new, :create, :cancel]
  #at the moment, only allow admins to reset the tokens
  before_filter :authorise_as_admin, :only =>[:edit] 
  def edit
    render 'devise/registrations/edit'
  end
  
  def redirect_root
    redirect_to(root_path)
  end
end
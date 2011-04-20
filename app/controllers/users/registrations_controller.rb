class Users::RegistrationsController < Devise::RegistrationsController
  before_filter :redirect_root, :only => [:new, :create, :cancel]
   
  def redirect_root
    redirect_to(root_path)
  end
end
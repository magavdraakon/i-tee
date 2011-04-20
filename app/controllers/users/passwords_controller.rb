class Users::PasswordsController < Devise::PasswordsController
  before_filter :redirect_root
   
  def redirect_root
    redirect_to(root_path)
  end
end
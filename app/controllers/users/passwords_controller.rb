class Users::PasswordsController < Devise::PasswordsController
  
  #at the moment, only allow managers 
  before_action :authorise_as_manager
end
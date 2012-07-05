class Users::PasswordsController < Devise::PasswordsController
  
  #at the moment, only allow managers 
  before_filter :authorise_as_manager
end
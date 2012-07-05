class Users::RegistrationsController < Devise::RegistrationsController

  #at the moment, only allow managers 
  before_filter :authorise_as_manager
  
end
class HomeController < ApplicationController
   before_filter :authorise_as_admin, :only=>[:system_info, :template_info]
  
  def index
  end

  def error_401
    
  end
  
  def system_info
  end
  
  def template_info
  end
  
  def profile
    @user=current_user
  end
end

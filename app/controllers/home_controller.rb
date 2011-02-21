class HomeController < ApplicationController
  layout 'main'
  
  def index
  end

  def error_401
    
  end
  
  def profile
    @user=current_user
  end
end

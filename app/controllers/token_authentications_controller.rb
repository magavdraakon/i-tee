class TokenAuthenticationsController < ApplicationController
   #at the moment, only allow admins to reset the tokens
  before_filter :authorise_as_admin
   def create
	    @user = User.find_by_id(params[:user_id])
	    @user.reset_authentication_token!
	    redirect_to :back
	  end
	 
	  def destroy
	    @user = User.find_by_id(params[:id])
	    @user.authentication_token = nil
	    @user.save
	    redirect_to :back
	  end
end

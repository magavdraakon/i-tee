class TokenAuthenticationsController < ApplicationController
   #at the moment, only allow managers to reset the tokens
  before_filter :authorise_as_manager
  before_filter :manager_tab
 
  def edit
    @user = User.find_by_id(params[:id])
    
  end
  
  def update
    if params[:commit]=='cancel'
      redirect_to users_path
    else
      
	    @user = User.find(params[:id])
      @user.reset_authentication_token! if params[:reset]
      @user.token_expires=DateTime.new( params[:user]['token_expires(1i)'].to_i,
                                      params[:user]['token_expires(2i)'].to_i,
                                      params[:user]['token_expires(3i)'].to_i,
                                      params[:user]['token_expires(4i)'].to_i,
                                      params[:user]['token_expires(5i)'].to_i)
      respond_to do |format|
        if @user.save
         format.html { redirect_to(users_path, :notice => 'successful update.') }
         format.xml  { head :ok }
        else
         format.html { render :action => 'edit' }
         format.xml  { render :xml => @user.errors, :status => :unprocessable_entity }
       end
      end
    end
	end
	 
	  def destroy
	    @user = User.find_by_id(params[:id])
	    @user.authentication_token = nil
	    @user.save
	    redirect_to :back
	  end
end

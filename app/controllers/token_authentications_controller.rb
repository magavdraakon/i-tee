class TokenAuthenticationsController < ApplicationController
   #at the moment, only allow managers to reset the tokens
  before_action :authorise_as_manager
  before_action :manager_tab
  before_action :set_user
 
  def edit    
  end
  
  def update
    if params[:commit]=='cancel'
      redirect_to users_path
    else
      @user.reset_authentication_token! if params[:reset]
      @user.token_expires = DateTime.new( params[:user]['token_expires(1i)'].to_i,
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
    @user.authentication_token = nil
    @user.save
    redirect_back fallback_location: manage_tokens_path
  end


private # -------------------------------------------------------
  def set_user
    @user = User.where(id: params[:id]).first
    unless @user
      redirect_to(users_path,:notice=>'invalid id.')
    end
  end

end

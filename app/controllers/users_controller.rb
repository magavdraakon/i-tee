class UsersController < ApplicationController
  before_filter :authorise_as_manager
  before_filter :manager_tab
  
  def index
    @users= User.find_by_sql("select id, username, last_sign_in_at, ldap, email, last_sign_in_ip from users")
    @users=@users.paginate(:page=>params[:page], :per_page=>10)
    
  end
  
  def edit
    @user=User.find(params[:id])
  end
  
  def new
    @user=User.new
  end
  
  def create
    @user = User.new(params[:user])
    @user.password="randomness"
    @user.ldap=false
    @user.ldap=true if params[:ldap_user]=="yes"
    respond_to do |format|
      if @user.save
        if params[:token] then
          #TODO:  Tokeni loomine
          @user.reset_authentication_token!
          @user.token_expires=DateTime.new( params[:token]["expires(1i)"].to_i,
                                      params[:token]["expires(2i)"].to_i,
                                      params[:token]["expires(3i)"].to_i,
                                      params[:token]["expires(4i)"].to_i,
                                      params[:token]["expires(5i)"].to_i)
          @user.save
        end
        format.html { redirect_to(users_path, :notice => 'User was successfully created.') }
        format.xml  { render :xml => @user, :status => :created, :location => @user }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @user.errors, :status => :unprocessable_entity }
      end
    end
  end
  
  def update
    @user = User.find(params[:id])
    @user.ldap=false
    @user.ldap=true if params[:ldap_user]=="yes"
    if params[:generate_token]=="yes" then
      @user.reset_authentication_token!
      @user.token_expires=DateTime.new( params[:token]["expires(1i)"].to_i,
                                      params[:token]["expires(2i)"].to_i,
                                      params[:token]["expires(3i)"].to_i,
                                      params[:token]["expires(4i)"].to_i,
                                      params[:token]["expires(5i)"].to_i)
    end
    respond_to do |format|
      if @user.update_attributes(params[:user])
        format.html { redirect_to(users_path, :notice => 'User was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @user.errors, :status => :unprocessable_entity }
      end
    end
  end
  
  def destroy
    @user = User.find(params[:id])
    @user.destroy

    respond_to do |format|
      format.html { redirect_to(:back) }
      format.xml  { head :ok }
    end
  end
end
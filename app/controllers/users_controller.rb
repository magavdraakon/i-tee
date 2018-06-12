class UsersController < ApplicationController
  before_action :authorise_as_manager, :except=>['show']
  before_action :manager_tab, :except=>['show']
  before_action :user_tab, :only=>['show']
  before_action :set_user, :only=>[:show, :edit, :update, :destroy]

  def index
    set_order_by
    #@users= User.find_by_sql("select id, username, last_sign_in_at, ldap, email, last_sign_in_ip from users")
    #@users= @users.paginate(:page=>params[:page], :per_page=>10).order(order)
    @users = User.select('id, name, username, role, last_sign_in_ip, last_sign_in_at, ldap, email, authentication_token, token_expires').order(@order).paginate(:page=>params[:page], :per_page=>@per_page)
    if params[:conditions]
      users = User.where(params[:conditions].as_json)
    else
      users = User.all
    end
    respond_to do |format|
      format.html 
      format.json  { render :json => users }
    end
  end
  
  def show
  end

  def edit
  end
  
  def new
    @user=User.new
  end
  
  def create
    params[:user] = (params[:user] ? params[:user] : params[:new_user])
    @user = User.new(user_params)
    @user.password = 'randomness' unless params[:user][:password] || params[:new_user][:password]
    @user.ldap = false
    @user.ldap = true if params[:ldap_user]=='yes'
    respond_to do |format|
      if @user.save
        if params[:user][:token_expires] || params[:new_user][:token_expires] # if time is sent, generate new token
          logger.debug "generating token"
          @user.reset_authentication_token!
        end
        if params[:token]
          #TODO:  Tokeni loomine
          @user.reset_authentication_token!
          @user.token_expires = DateTime.new( params[:token]['expires(1i)'].to_i,
                                      params[:token]['expires(2i)'].to_i,
                                      params[:token]['expires(3i)'].to_i,
                                      params[:token]['expires(4i)'].to_i,
                                      params[:token]['expires(5i)'].to_i)
         
        end
        @user.save
        format.html { redirect_to(users_path, :notice => 'User was successfully created.') }
        format.json  { render :json =>{ :success=> true, :user=> @user.as_json}, :status => :created }
      else
        format.html { render :action => 'edit' }
        format.json  { render :json => { :success=> false, :errors => @user.errors}, :status => :unprocessable_entity }
      end
    end
  end
  
  def update
    params[:user] = (params[:user] ? params[:user] : params[:new_user])
    respond_to do |format| 
      if @user
        @user.ldap = false
        @user.ldap = true if params[:ldap_user]=='yes'
        if params[:user][:token_expires] # if time is sent, generate new token
          @user.reset_authentication_token!
        end
        if params[:generate_token]=='yes'
          @user.reset_authentication_token!
          @user.token_expires = DateTime.new( params[:token]['expires(1i)'].to_i,
                                            params[:token]['expires(2i)'].to_i,
                                            params[:token]['expires(3i)'].to_i,
                                            params[:token]['expires(4i)'].to_i,
                                            params[:token]['expires(5i)'].to_i)
        end

        if @user.update_attributes(user_params)
          format.html { redirect_to(users_path, :notice => 'User was successfully updated.') }
          format.json  { render :json=> { :success=> true, :user=> @user.as_json}}
        else
          format.html { render :action => 'edit' }
          format.json  { render :json => { :success=> false, :errors => @user.errors}, :status => :unprocessable_entity }
        end
      else
        format.html { 
          flash[:notice]= "Can't find user"
          redirect_back fallback_location: users_path
         }
        format.json { render :json=> { :success=>false, :message=> "Can't find user"} }
      end
    end
  end
  
  def destroy
    respond_to do |format|
      if @user
        logger.debug "\n user removal START \n"
        logger.debug @user.as_json
        @user.destroy
        logger.debug "\n user removal END \n"
        format.html { redirect_back fallback_location: users_path) }
        format.json { render :json=> { :success=>true, :message=> 'user removed'} }
      else
        format.html { 
          flash[:notice]= "Can't find user"
          redirect_back fallback_location: users_path
        }
        format.json { render :json=> { :success=>false, :message=> "Can't find user"} }
      end
    end
  end

private # -------------------------------------------------------
  def set_user
    @user = User.where(id: params[:id]).first
    unless @user
      redirect_to(users_path,:notice=>'invalid id.')
    end
  end

  def user_params
    if !params[:user].empty?
      logger.debug "user is present"
      params.require(:user).permit(:id, :email, :password, :username, :name, :authentication_token, :token_expires, :ldap, :role)
    elsif !params[:new_user].empty?
      logger.debug "new_user is present"
      params.require(:new_user).permit(:id, :email, :password, :username, :name, :authentication_token, :token_expires, :ldap, :role)
    end  

  end
end
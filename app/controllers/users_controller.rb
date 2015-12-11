class UsersController < ApplicationController
  before_filter :authorise_as_manager, :except=>['show']
  before_filter :manager_tab, :except=>['show']
  before_filter :user_tab, :only=>['show']
  
  def index
    set_order_by
    #@users= User.find_by_sql("select id, username, last_sign_in_at, ldap, email, last_sign_in_ip from users")
    #@users= @users.paginate(:page=>params[:page], :per_page=>10).order(order)
    @users = User.select('id, name, username, role, last_sign_in_ip, last_sign_in_at, ldap, email, authentication_token, token_expires').order(@order).paginate(:page=>params[:page], :per_page=>@per_page)
    users= User.all if !params[:conditions]
    users = User.where(params[:conditions].as_json) if params[:conditions]
    respond_to do |format|
      format.html 
      format.json  { render :json => users }
    end
  end
  
  def show
    @user=User.find(params[:id])

  end

  def edit
    @user=User.find(params[:id])
  end
  
  def new
    @user=User.new
  end
  
  def create
    user = params[:user] ? params[:user] : params[:new_user]
    @user = User.new(user)
    @user.password='randomness' unless user[:password]
    @user.ldap=false
    @user.ldap=true if params[:ldap_user]=='yes'
    respond_to do |format|
      if @user.save
        if user[:token_expires] # if time is sent, generate new token
          @user.reset_authentication_token!
        end
        if params[:token]
          #TODO:  Tokeni loomine
          @user.reset_authentication_token!
          @user.token_expires=DateTime.new( params[:token]['expires(1i)'].to_i,
                                      params[:token]['expires(2i)'].to_i,
                                      params[:token]['expires(3i)'].to_i,
                                      params[:token]['expires(4i)'].to_i,
                                      params[:token]['expires(5i)'].to_i)
          @user.save
        end
        format.html { redirect_to(users_path, :notice => 'User was successfully created.') }
        format.json  { render :json =>{ :success=> true}.merge(@user.as_json), :status => :created }
      else
        format.html { render :action => 'edit' }
        format.json  { render :json => { :success=> false, :errors => @user.errors}, :status => :unprocessable_entity }
      end
    end
  end
  
  def update
    user = params[:user] ? params[:user] : params[:new_user]
    @user = User.where("id=?",params[:id]).first
    respond_to do |format| 
      unless @user
        format.html { redirect_to(:back, :notice=> "Can't find user") }
        format.json { render :json=> { :success=>false, :message=> "Can't find user"} }
      end
      @user.ldap=false
      @user.ldap=true if params[:ldap_user]=='yes'
      if user[:token_expires] # if time is sent, generate new token
        @user.reset_authentication_token!
      end
      if params[:generate_token]=='yes'
        @user.reset_authentication_token!
        @user.token_expires=DateTime.new( params[:token]['expires(1i)'].to_i,
                                        params[:token]['expires(2i)'].to_i,
                                        params[:token]['expires(3i)'].to_i,
                                        params[:token]['expires(4i)'].to_i,
                                        params[:token]['expires(5i)'].to_i)
      end
    
      if @user.update_attributes(user)
        format.html { redirect_to(users_path, :notice => 'User was successfully updated.') }
        format.json  { render :json=> { :success=> true}.merge(@user.as_json)}
      else
        format.html { render :action => 'edit' }
        format.json  { render :json => { :success=> false, :errors => @user.errors}, :status => :unprocessable_entity }
      end
    end
  end
  
  def destroy
    @user = User.where("id=?", params[:id]).first
    respond_to do |format|
      if @user
        @user.destroy
        format.html { redirect_to(:back) }
        format.json { render :json=> { :success=>true, :message=>"user removed"} }
      else
        format.html { redirect_to(:back, :notice=> "Can't find user") }
        format.json { render :json=> { :success=>false, :message=> "Can't find user"} }
      end
    end
  end

end
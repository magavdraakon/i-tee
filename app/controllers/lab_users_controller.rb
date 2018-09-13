class LabUsersController < ApplicationController
  before_action :authorise_as_manager
  #restricted to admins
  before_action :authorise_as_manager, :except=>[ :labinfo ]
  #redirect to index view when trying to see unexisting things
  before_action :get_user, :only=>[:create ,:show, :edit, :update, :destroy, :set_vta]
  before_action :save_from_nil, :only=>[:show, :edit, :update, :destroy, :set_vta]

  before_action :manager_tab, :except=>[:search]
  before_action :search_tab, :only=>[:search]

  def save_from_nil
    if params[:id] # find by id
      @lab_user = LabUser.where('id=?',params[:id]).first
      if @lab_user.blank? # cant find!
        respond_to do |format|
           format.html  {redirect_to lab_users_path, :notice=>'Invalid  id.' }
           format.json  { render :json => {:success=>false, :message=>"Can't find lab user"} }
        end
      end
    elsif params[:lab_id] # find by lab_id and userid/username
      if @user
        @lab_user = LabUser.where('user_id=? and lab_id=?', @user.id, params[:lab_id]).last # last is the newest
        if @lab_user.blank? # cant find!
          respond_to do |format|
             format.html  {redirect_to lab_users_path, :notice=>'Invalid  id.' }
             format.json  { render :json => {:success=>false, :message=>"Can't find lab user"} }
          end
        end
      else # cant find user! 
        respond_to do |format|
          format.html { redirect_to(lab_users_path) }
          format.json { render :json=> { :success=> false, :message=>"user can't be found"} } 
        end 
      end
    end
  end

  
  # GET /lab_users
  # GET /lab_users.xml
  #index and new view are merged
  def index
    #@lab_users = LabUser.find(:all, :order=>params[:sort_by])
    set_order_by
    @lab_users = LabUser.order(@order).paginate(:page => params[:page], :per_page => @per_page)
    @lab_user = LabUser.new
    @users= User.order('username')
    if request.format == 'json'
      if params[:conditions]
        conditions = params[:conditions].as_json
        #fix start and end
        if conditions[:end] && conditions[:end]==''
          conditions[:end]=nil
        end
        if conditions && conditions[:start]==''
          conditions[:start]=nil
        end
        logger.info "FIND LABUSER: #{conditions}"
        labusers = LabUser.where(conditions)
      else
        labusers = LabUser.all
      end
      if params[:with_ping]
        labusers = labusers.map{|l| l.with_ping}
      end
    end
    respond_to do |format|
      format.html # index.html.erb
      format.json  { render :json => labusers }
    end
  end
  
# for search view to display user machines in an attempt
  def show
    @info={:running=>[], :paused=>[], :stopped=>[]}
    @lab_user.vms.each do |v|
      v['username']=@lab_user.user.username
      v['port'] = v.rdp_port
      logger.debug "state is #{v.state}"
      @info[:"#{v.state}"]<< v
    end
    respond_to do |format|
      format.json  { render :json => @info }
    end
  end

  # GET /lab_users/1/edit
  def edit
    #@lab_user = LabUser.find(params[:id])
  end

  # POST /lab_users
  # POST /lab_users.xml
  def create
    set_order_by
    @lab_users = LabUser.order(@order).paginate(:page => params[:page], :per_page => @per_page)
    # logic for when adding/removing multiple users at once to a specific lab
    if params[:lab_user] && params[:lab_user][:page]=='bulk_add'
      LabUser.add_users(params)
      flash[:notice] = 'successful update.'
      redirect_back fallback_location: add_users_path
    else #adding a single user to a lab
      respond_to do |format|
        #create lab_user params based on lab_id and user_id
        if params[:lab_id]
          params[:lab_user] = { lab_id: params[:lab_id] }
          if @user
            params[:lab_user][:user_id] = @user.id
          end
        end
        # continue to create
        @lab_user = LabUser.new(labuser_params)

        if @lab_user.save
          format.html { 
            flash[:notice] = 'successful update.' 
            redirect_back fallback_location: lab_users_path
          }
          format.json { 
            logger.info "LABUSER CREATE SUCCESS: labuser=#{@lab_user.id} lab=#{@lab_user.lab.id} user=#{@lab_user.user.id} [#{@lab_user.user.username}]"
            render :json=> {:success => true, :lab_user => @lab_user}, :status=> :created
          }
        else
          format.html { render :action => 'index' }
          format.json { 
            logger.error "LABUSER CREATE FAILED: lab=#{params[:lab_id]} user=#{params[:user_id]} " + ( @user ? "[#{user.username}]" : '')
            logger.error @lab_user.errors.as_json
            render :json=> {:success => false, :errors => @lab_user.errors}, :status=> :unprocessable_entity
          }
        end #end if
      end #end respond_to
    end #end else
  end

  # PUT /lab_users/1
  # PUT /lab_users/1.xml
  def update
    respond_to do |format|
      if @lab_user.update_attributes(labuser_params)
        format.html {
          flash[:notice] = 'successful update.' 
          redirect_back fallback_location: lab_users_path
        }
        format.json  { render :json=>{:success=>true, :lab_user=>@lab_user.as_json} }
      else
        format.html { render :action => 'edit' }
        format.json  { render :json => {:success=>false, :errors=> @lab_user.errors}, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /lab_users/1
  # DELETE /lab_users/1.xml
  def destroy
    respond_to do |format|
      #when removing someone from a lab, you need to end their lab
      @lab_user.end_lab
      @lab_user.destroy

      format.html { redirect_to(lab_users_path) }
      format.json { render :json=> { :success=>true, :message=>'lab user removed'} }
    end
  end

  # get vta info from outside {host: 'http://', token: 'lab-specific update token', lab_hash: 'vta lab id', user_key: 'user token'}
  def set_vta
    respond_to do |format|
      format.html { redirect_to(lab_users_path) }
      format.json { render :json=> @lab_user.set_vta(params) }
    end
  end

  # return labuser and it's lab info based on labuser uuid
  def labinfo
    respond_to do |format|
      format.html { redirect_to(root_path, notice: 'Invalid request') }
      format.json { render :json=> ImportLabs.export_labuser(params[:uuid], params[:pretty]) }
    end
  end

  #view for adding multiple users to a lab
  def add_users
    @lab_users = LabUser.all
    @lab_user = LabUser.new 
    @lab = false
    if params[:id] # find lab by url id
      @lab = Lab.where(id: params[:id]).first
    elsif session[:lab_id] # if there is no url id, but a session lab_id exists, use that to find the lab
      @lab = Lab.where(id: session[:lab_id]).first 
    end
    #if no lab is found, take the first
    @lab = Lab.first unless @lab
    # if there are no labs - redirect away
    if @lab.blank?
      redirect_to users_path, notice: "No labs are added to I-Tee, therefore this action is not available." 
    else
      session[:lab_id]=@lab.id # remember for next time
      #users already in the particular lab
      @users_in=[]
      @lab.lab_users.each do |u|
        @users_in<<u.user
      end
    end
  end
  
  def import
    @lab=Lab.find_by_id(params[:lab_id])
    if params[:txtsbs].present? && @lab!=nil
      @upload_text = params[:txtsbs].read
      
      u_missing = []
      n_missing = []
      t_missing = []
      failed = []
      @upload_text.each_line.with_index do |u, index|        
        u.chomp!
        user = u.split(',')#username,realname, email, token (username and name compulsory for everyone, email not?)
        if user.empty?
          failed << (index+1)
          next
        end
        if user[0].blank? 
          u_missing << (index+1)
          next
        end
        if user[1].blank?
          user[1] = user[0].gsub(' ', '') unless user[0].blank? # use username as fullname
          n_missing << (index+1) if user[1].blank?
          next
        end
        @user=User.where('username=?', user[0]).first
        if @user==nil #user doesnt exist
          email = user[2].gsub(' ','')
          if email == nil || email == ''
           email="#{user[0]}@itcollege.ee"
          end
          #TODO: email is username@itcollege when email is set??? take address (@something.end) from config?
          if user[3]
            password = SecureRandom.urlsafe_base64(16)
            data = {:email=>email ,:username=>user[0], :name=>user[1] ,:password=>password}
            @user = User.create!(data)
          else
            t_missing << (index+1)
          end
        end
        if @user # only if user exists / was created
          if user[1]
            @user.name = user[1]
          end
          if user[3] # if token is given
            @user.authentication_token=user[3]
            @user.token_expires = 2.weeks.from_now # TODO! default expiry time from settings?
          end
          @user.save
          labuser=LabUser.where('user_id=? and lab_id=?', @user.id, @lab.id).first
          # by now we surely have a user, add it to the lab
          if labuser==nil
            labuser=LabUser.new
            labuser.lab=@lab
            labuser.user=@user
            if labuser.save
             # do nothing when success
            else
              failed << (index+1)
            end
          else
            # do nothing when existed
          end
        end
      end
      #TODO: flash notice too long if more then 50 users?
      notice = ''
      notice += "#{failed.join(', ')} failed<br/>" unless failed.empty?
      notice += "#{u_missing.join(', ')} username missing<br/>" unless u_missing.empty?
      notice += "#{n_missing.join(', ')} name missing<br/>" unless n_missing.empty?
      notice += "#{t_missing.join(', ')} token missing" unless t_missing.empty?
      
      flash[:notice] = notice.html_safe
      redirect_back fallback_location: add_users_path

    else
      flash[:alert] = 'No import file specified.'
      redirect_back fallback_location: lab_users_path
    end
  end
  


# search and react to actions
  def search

    set_order_by
    if params[:t] && params[:t]=='User'
      if params[:id]  # updates based on selected users and actions
        users=get_users_from(params[:id])
        manage_users(users)
        users.each do |u| 
          manage_labusers(u.lab_users) if params[:lab]  # manage user labs 
          manage_vms(u.vms) if params[:vm]
        end
      end # end updates
       # search again with new values
      @users=User.order(@order).where('LOWER(username) like ?', "%#{params[:u].downcase}%").all
    elsif params[:t] && params[:t]=='Lab'
      if params[:id]
        labs=get_labs_from(params[:id])
        labs.each do |lab|
          manage_users(lab.users)
          if params[:lab] && params[:lab]=='remove_all_users'
            lab.remove_all_users
          elsif params[:lab] && params[:lab]=='add_all_users'
            lab.add_all_users
          elsif params[:lab]
            manage_labusers(lab.lab_users) 
          end
          manage_vms(lab.vms) if params[:vm]
        end
      end # end updates
      @labs = Lab.order(@order).where('LOWER(labs.name) like ?', "%#{params[:l].downcase}%").all
    elsif params[:t] && params[:t]=='Lab user'
      if params[:id]
        lab_users=get_lab_users_from(params[:id])
        manage_labusers(lab_users) if params[:lab]
        lab_users.each do |lu|
          manage_users([lu.user]) # action requires array
          manage_vms(lu.vms) if params[:vm]
        end
      end #end updates

      @lab_users = LabUser.joins(:user, :lab).order(@order).where('LOWER(labs.name) like ? and LOWER(users.username) like ? ', "%#{params[:l].downcase}%", "%#{params[:u].downcase}%").all
    end

  end

  def user_token
    set_order_by
    @users = User.order(@order).paginate(:page=>params[:page], :per_page=>@per_page)
  end
  
  private #-----------------------------------------------

  def labuser_params
    params.require(:lab_user).permit(:id, :lab_id, :user_id, :result, :start, :pause, :end, :last_activity, :activity, :g_user, :g_username, :g_password, :vta_setup, :uuid, :token)
  end

  def get_user
    @user=current_user # by default get the current user
    if @admin  #  admins can use this to view users labs
      if params[:username]  # if there is a username in the url
        @user = User.where('username = ?',params[:username]).first
      end
      if params[:user_id]  # if there is a user_id in the url
        @user = User.where('id = ?',params[:user_id]).first
      end
    end
  end

  # return a array of users based on the input (list of checked checkboxes)
  def get_users_from(id_list)
    id_list=[] if id_list.blank?
    User.where(id: id_list)
  end
  def get_lab_users_from(id_list)
    id_list=[] if id_list.blank?
    LabUser.where(id: id_list)
  end
  def get_labs_from(id_list)
    id_list=[] if id_list.blank?
    Lab.where(id: id_list)
  end

  def manage_labusers(lab_users)
    lab_users.each do |lu| 
      if params[:lab]=='end'  # end all labs
        lu.end_lab
      elsif params[:lab]=='restart' # restart all labs
        # TODO! should restart only stopped labs?
        lu.restart_lab
      elsif params[:lab]=='remove' # remove all labs
        lu.destroy
      end
    end
  end

  def manage_vms(vms)
    vms.each do |v|
      if params[:vm]=='poweroff'
        v.stop_vm
      elsif params[:vm]=='poweron'
        v.start_vm
      elsif params[:vm]=='reset_rdp'
        v.reset_rdp
      end
    end
  end

  def manage_users(users)
    users.each do |u|
      if params[:user] && params[:user]=='destroy'
        u.destroy
        next
      end
      if params[:reset_token]  # reset token only if checked
        logger.debug '\n reset token \n'
        u.reset_authentication_token!
      end

      if params[:reset_token_expire] # reset token expire time
        logger.debug '\n reset token expire date \n'
        u.token_expires=DateTime.new( params[:user]['token_expires(1i)'].to_i,
                                      params[:user]['token_expires(2i)'].to_i,
                                      params[:user]['token_expires(3i)'].to_i,
                                      params[:user]['token_expires(4i)'].to_i,
                                      params[:user]['token_expires(5i)'].to_i)
        u.save
      end

      if params[:remove_token] # remove token and expire time
        u.authentication_token = nil
        u.token_expires=nil
        u.save
      end
    end
  end
end

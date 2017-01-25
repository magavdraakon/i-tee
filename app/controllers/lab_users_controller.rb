class LabUsersController < ApplicationController
  #restricted to admins 
  before_filter :authorise_as_manager, :except=>[:progress]
  #redirect to index view when trying to see unexisting things
  before_filter :save_from_nil, :only=>[:edit, :update, :destroy]
  before_filter :manager_tab, :except=>[:search]
  before_filter :search_tab, :only=>[:search]

  def save_from_nil
    if params[:id] # find by id
      @lab_user = LabUser.where('id=?',params[:id]).first
      if @lab_user==nil # cant find!
        respond_to do |format|
           format.html  {redirect_to lab_users_path, :notice=>'Invalid  id.' }
           format.json  { render :json => {:success=>false, :message=>"Can't find lab user"} }
        end
      end
    elsif params[:lab_id] # find by lab_id and userid/username
      get_user
      if @user
        @lab_user = LabUser.where('user_id=? and lab_id=?', @user.id, params[:lab_id]).last # last is the newest
        if @lab_user==nil # cant find!
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
        #fix start and end
        if params[:conditions][:end] && params[:conditions][:end]==''
          params[:conditions][:end]=nil
        end
        if params[:conditions] && params[:conditions][:start]==''
          params[:conditions][:start]=nil
        end
        logger.debug "\n query params #{params[:conditions]}\n"
        labusers = LabUser.where(params[:conditions])
      else
        labusers = LabUser.all
      end
    end
    respond_to do |format|
      format.html # index.html.erb
      format.json  { render :json => labusers }
    end
  end
  
# for search view to display user machines in an attempt
  def show
    @lab_user = LabUser.find_by_id(params[:id])
    @info={:running=>[], :paused=>[], :stopped=>[]}
    @lab_user.vms.each do |v|
      v['username']=@lab_user.user.username
      v['port']='10'+v.mac.ip.split('.').last if v.mac!=nil
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
      all_users=User.all
      checked_users=get_users_from(params[:users])
      removed_users=all_users-checked_users
      lab=params[:lab_user][:lab_id]
      checked_users.each do |c|
        l=LabUser.new
        l.lab_id=lab
        l.user_id=c.id
        #if there is no db row with the se parameters then create one
        # TODO: move to model
        if LabUser.where('lab_id=? and user_id=?', lab, c.id).first==nil
          l.save
        end
      end
      removed_users.each do |d|
        #look for the unchecked users and remove them from db if they were there
        l=LabUser.where('lab_id=? and user_id=?', lab, d.id).first
        l.delete if l!=nil
      end
      redirect_to(:back, :notice => 'successful update.')
    else #adding a single user to a lab
      respond_to do |format|
        #create lab_user params based on lab_id and user_id
        if params[:lab_id]
          params[:lab_user] = { lab_id: params[:lab_id] }
          get_user
          if @user
            params[:lab_user][:user_id] = @user.id
          end
        end
        # continue to create
        @lab_user = LabUser.new(params[:lab_user])

        if @lab_user.save
          format.html { redirect_to(:back, :notice => 'successful update.') }
          format.json { render :json=> {:success => true}.merge(@lab_user.as_json), :status=> :created}
        else
          format.html { render :action => 'index' }
          format.json { render :json=> {:success => false, :errors => @lab_user.errors}, :status=> :unprocessable_entity}
        end #end if
      end #end respond_to
    end #end else
  end

  # PUT /lab_users/1
  # PUT /lab_users/1.xml
  def update
    respond_to do |format|
      if @lab_user.update_attributes(params[:lab_user])

        format.html { redirect_to(:back, :notice => 'successful update.') }
        format.json  { render :json=>{:success=>true}.merge(@lab_user.as_json) }
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
  
  #view for adding multiple users to a lab
  def add_users
    @lab_users = LabUser.all
    @lab_user = LabUser.new 
    # find lab by url id
    @lab=Lab.find_by_id(params[:id]) if params[:id]
    # if there is no url id, but a session lab_id exists, use that to find the lab
    @lab=Lab.find_by_id(session[:lab_id]) if session[:lab_id] and !params[:id]
    #if no lab is found, take the first
    if @lab==nil
      @lab=Lab.first
      redirect_to(add_users_path) if params[:id]!=nil
    end
    session[:lab_id]=@lab.id # remember for next time
    #users already in the particular lab
    @users_in=[]
    @lab.lab_users.each do |u|
      @users_in<<u.user
    end
  end
  
  def import
    @lab=Lab.find_by_id(params[:lab_id])
    if params[:txtsbs].present? && @lab!=nil
      @upload_text = params[:txtsbs].read
      users=@upload_text.split('\n')
      
      notice=''
      @upload_text.each_line do |u| 
        
      #users.each do |u|
      #while u = params[:txtsbs].readline        
        u.chomp!
        user=u.split(',')#username,realname, email, token (username compulsory for everyone, real name and email not?)
        if user.empty? || user[0]==nil || user[0]==''
          notice=notice+'adding user "<b>'+u+'</b>" failed '
          notice=notice+' - needs username' if user[0]==nil || user[0]==''
          notice=notice+'<br/>'
          next
        end
        @user=User.where('username=?', user[0]).first
        if @user==nil #user doesnt exist
          email=user[2]
          if email == nil || email == ''
           email="#{user[0]}@itcollege.ee"
          end

          #TODO: email is username@itcollege when email is set??? take address (@something.end) from config?
          if user[3]
            @user=User.create!(:email=>email ,:username=>user[0], :name=>user[1] ,:password=>user[3])
          else
            notice=notice+'<b>'+user[0]+'</b> adding failed - token needed for new users<br/>'
          end
        end
        if @user # only if user exists / ws created
          if user[3] # if token is given
            @user.authentication_token=user[3]
            @user.token_expires = 2.weeks.from_now # TODO! default expiry time from settings?
            @user.save
          end

          labuser=LabUser.where('user_id=? and lab_id=?', @user.id, @lab.id).first
          # by now we surely have a user, add it to the lab
          if labuser==nil
            labuser=LabUser.new
            labuser.lab=@lab
            labuser.user=@user
            if labuser.save
              notice=notice+'<b>'+user[0]+'</b> added successfully<br/>'
            else
              notice=notice+'<b>'+user[0]+'</b> adding failed<br/>'
            end
          else
            notice=notice+'<b>'+user[0]+'</b> was already in the lab<br/>'
          end
        end
      end

      redirect_to(:back, :notice=>notice.html_safe)
    else
      redirect_to(:back, :alert=>'No import file specified.')
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
      if params[:h]==''
        @labs = Lab.joins('left join hosts on hosts.id=labs.host_id').order(@order).where('LOWER(labs.name) like ?', "%#{params[:l].downcase}%").all
      else
        @labs = Lab.joins('left join hosts on hosts.id=labs.host_id').order(@order).where('LOWER(labs.name) like ? and LOWER(hosts.name) like ?', "%#{params[:l].downcase}%", "%#{(params[:h] ? params[:h] : '').downcase}%").all
      end
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



  def progress
    @lab_user=LabUser.find_by_id(params[:id])
    unless @lab_user.user.id==current_user.id || @admin
      @lab_user=LabUser.new#dummy
    end
    render :partial => 'shared/lab_progress' 
  end
  
  def user_token
    set_order_by
    @users= User.order(@order).paginate(:page=>params[:page], :per_page=>@per_page)
  end
  
  private #-----------------------------------------------


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
    id_list.collect{|u| User.find_by_id(u.to_i)}.compact
  end
   def get_lab_users_from(id_list)
    id_list=[] if id_list.blank?
    id_list.collect{|u| LabUser.find_by_id(u.to_i)}.compact
  end
   def get_labs_from(id_list)
    id_list=[] if id_list.blank?
    id_list.collect{|u| Lab.find_by_id(u.to_i)}.compact
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

class LabsController < ApplicationController  
  #users can see courses, running labs and end their OWN lab
  before_filter :authorise_as_admin, :except => [:user_labs, :start_lab, :end_lab, :restart_lab]

  #redirect to index view when trying to see unexisting things
  before_filter :get_lab, :only=>[:show, :edit, :update]
  # set the menu tab to show the user
  before_filter :course_tab, :only=>[:user_labs]
  before_filter :admin_tab, :except=>[:user_labs]
    
  
  def get_lab
    @lab = Lab.where('id=?',params[:id]).first
    unless @lab 
      respond_to do |format|
         format.html  {redirect_to my_labs_path, :notice=>'Invalid lab id.' }
         format.json  { render :json => {:success=>false, :message=>"Can't find lab"} }
      end
    end
  end
  
  # GET /labs
  # GET /labs.xml
  def index
    set_order_by
    @labs = Lab.order(@order).paginate(:page=>params[:page], :per_page=>@per_page)
    if params[:conditions]
      labs = Lab.where(params[:conditions].as_json)
    else
      labs = Lab.all
    end
    respond_to do |format|
      format.html # index.html.erb
      format.json  { render :json => labs }
    end
  end

  # GET /labs/1
  # GET /labs/1.xml
  def show
    #@lab = Lab.find(params[:id])
    @lab_vmt=LabVmt.new
    @lab_badge=LabBadge.new
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @lab }
    end
  end

  # GET /labs/new
  # GET /labs/new.xml
  def new
    @lab = Lab.new
    @lab.lab_vmts.build.lab_vmt_networks.build
    @all_users=false
    @user_count=0
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @lab }
    end
  end

  # GET /labs/1/edit
  def edit
    @lab.lab_vmts.each do |v|
      v.lab_vmt_networks.build
    end
    @lab.lab_vmts.build.lab_vmt_networks.build
    
    #@lab = Lab.find(params[:id])
    @all_users=false
    @user_count =0
    @user_count = @lab.lab_users.count  
    @all_users=true if User.all.count==@user_count
  end
  
  # POST /labs
  # POST /labs.xml
  def create
    @lab = Lab.new(params[:lab])
    @all_users=false
    @user_count=0
    respond_to do |format|
      if @lab.save
                
        @lab.add_all_users  if params[:add] && params[:add].to_s==1.to_s
        @lab.remove_all_users if params[:remove] && params[:remove].to_s==1.to_s 
        
        format.html { redirect_to(@lab, :notice => "Lab was successfully created. #{params[:add]}") }
        format.json  { render :json => { :success => true }.merge(@lab.as_json) }
      else
        format.html { render :action => 'new' }
        format.json  { render :json => {:success=>false, :errors=>@lab.errors}, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /labs/1
  # PUT /labs/1.xml
  def update
    respond_to do |format|
      @all_users=false
      @user_count =0
      @user_count = @lab.lab_users.count  
      @all_users=true if User.all.count==@user_count
      if @lab.update_attributes(params[:lab])
       
        @lab.add_all_users  if params[:add].to_s==1.to_s    
        @lab.remove_all_users if params[:remove].to_s==1.to_s 
          
        format.html { redirect_to(@lab, :notice => 'Lab was successfully updated.') }
        format.json  { render :json => {:success=>true}.merge(@lab.as_json)}
      else
        format.html { render :action => 'edit' }
        format.json  { render :json => {:success=>false, :errors=>@lab.errors}, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /labs/1
  # DELETE /labs/1.xml
  def destroy
    @lab = Lab.where('id=?',params[:id]).first
    respond_to do |format|
        if @lab
          @lab.destroy

          format.html { redirect_to(labs_url, :notice=>'Lab deleted') }
          format.json  { render :json => {:success=>true, :message=>'Lab deleted'} }
        else
          format.html { redirect_to(labs_url, :notice=>"Can't find lab") }
          format.json  { render :json => {:success=>false, :message=>"Can't find lab"}}
        end
    end
  end

# search for labs to end all of their attempts (lab_users) etc.
 def search

 end

  # view and do labs - user view
  def user_labs
    get_user # @user - either lab owner or current user
    if !@user && params[:username]
          logger.debug "There is no user named '#{params[:username]}'"
          flash[:notice] = "There is no user named '#{params[:username]}'"
          redirect_to :back and return
    elsif !@admin && params[:username] then # simple user should not have the username in url
      logger.debug "\nmy_labs: Relocate user\n"
      # simple user should not have the username in url
      redirect_to(my_labs_path+(params[:id] ? "/#{params[:id]}" : ''))
    else
      get_user_labs(@user) # @labs (all labs), @started, @complete, @not_started
      # if no course is selected show the first one
      if params[:id]!=nil
        @lab = Lab.find(params[:id])
      else
        @lab=@labs.first 
      end

      if @labs!=[] && @labs.include?(@lab)
        @lab_user = LabUser.where('lab_id=? and user_id=?', @lab.id, @user.id).last if @lab
      elsif @labs!=[]  # users with labs, that try to see others labs are redirected to error
        logger.debug "\n'#{current_user.username}' redirected: dont have lab '#{@lab.name}' (#{@lab.id}) \n"
        redirect_to(error_401_path) and return
      end
    end
    rescue ActionController::RedirectBackError # cant redirect back? go to the lab instead
      logger.info '\nNo :back error\n'
      redirect_to(my_labs_path+(params[:id] ? "/#{params[:id]}" : ''))
  end
  
  def start_lab_by_id
    respond_to do |format|
      if @admin && params[:labuser_id]
        @labuser= LabUser.where('id=?', params[:labuser_id]).first
        if @labuser
          # generating vm info if needed
          result =  @labuser.start_lab
          format.html { redirect_to(:back) }
          format.json {render :json=>{ :success => result[:success] , :message=> result[:message], :lab_user => @labuser.id, :start_time => @labuser.start }}
        else
          format.html { redirect_to :back , :notice=> "Can't find lab user" }
          format.json { render :json=> {:success => false , :message=>  "Can not find mission attempt" }}
        end
      else
        format.html { redirect_to :back , :notice=> 'Restricted access' }
        format.json { render :json=> {:success => false , :message=>  'No permission' }}
      end
    end
    rescue ActionController::RedirectBackError # cant redirect back? go to the lab instead
      logger.info "\nNo :back error\n"
      redirect_to(my_labs_path)
  end

  # method for starting a lab, creates virtual machine dbrows and sets the start time for the lab
  def start_lab
    respond_to do |format|
      @lab=Lab.find(params[:id])  
      get_user # @user - either lab owner or current user
      if !@user
        logger.debug "Can't find user: "
        logger.debug params
        format.html { redirect_to :back , :notice=> "Can not find user" }
        format.json { render :json=> {:success => false , :message=>  "Can not find user" }}
      elsif !@admin && (params[:username] || params[:user_id])
        logger.debug '\n start_lab: Relocate user\n'
        # simple user should not have the username in url
        format.html { redirect_to my_labs_path+(params[:id] ? "/#{params[:id]}" : '') }
        format.json { render :json=>{:success => false , :message=> 'No permission' }}
      else
        # ok, there is such lab, but does the user have it?
        @lab_user = LabUser.where('lab_id=? and user_id=?', @lab.id, @user.id).last
        if @lab_user!=nil       # yes, this user has this lab
          logger.debug "\nStarting '#{@lab_user.user.username}' lab '#{@lab_user.lab.name}' as admin\n" if @admin
          # generating vm info if needed
          result = @lab_user.start_lab
          format.html { redirect_to(:back, notice: result[:message]) }
          format.json {render :json=>{ :success => result[:success] , :message=> result[:message], :lab_user => @lab_user.id, :start_time => @lab_user.start }}
        else
          # no this user does not have this lab
          format.html { redirect_to my_labs_path, :notice => 'That lab was not assigned to this user!' }
          format.json { render :json=>{:success => false, :message=> 'That lab was not assigned to this user!' }}
        end
      end #is ok
    end
    rescue ActiveRecord::RecordNotFound
      respond_to do |format|
        logger.debug "Can't find lab: "
        logger.debug params
        format.html { redirect_to my_labs_path , :notice=> "Can't find lab" }
        format.json { render :json=> {:success => false , :message=>  "Can not find lab" }}
      end
    rescue ActionController::RedirectBackError # cant redirect back? go to the lab instead
      logger.info "\nNo :back error\n"
      redirect_to(my_labs_path+(@lab ? "/#{@lab.id}" : '')+(@lab && params[:username] ? "/#{params[:username]}" : ''))
  end
  
  def end_lab_by_id
    respond_to do |format|
      if @admin && params[:labuser_id]
        @labuser= LabUser.where('id=?', params[:labuser_id]).first
        if @labuser
          result = @labuser.end_lab
          logger.debug "mission #{@labuser.id} end result: #{result.as_json}"
          # back to the view the link was in
          format.html { redirect_to(:back, notice: result[:message]) }
          format.json {render :json=>{ :success => result[:success] , :message=> result[:message], :lab_user => @labuser.id , :end_time => @labuser.end}}
        else
          format.html { redirect_to :back , :notice=> "Can't find lab user" }
          format.json { render :json=> {:success => false , :message=>  "Can't find lab user" }}
        end
      else
        format.html { redirect_to :back , :notice=> 'Restricted access' }
        format.json { render :json=> {:success => false , :message=>  'No permission error' }}
      end
    end
    rescue ActionController::RedirectBackError # cant redirect back? go to the lab instead
      logger.info "\nNo :back error\n"
      redirect_to(my_labs_path)
  end

  # method to end lab by username and lab id
  def end_lab_by_values
    respond_to do |format|
      if @admin
        user = User.where("username=?", params[:user_name]).first
        if user
          @labuser = LabUser.where('lab_id=? and user_id=?', params[:lab_id], user.id ).last
          if @labuser
            result = @labuser.end_lab
            logger.debug "mission #{@labuser.id} end result: #{result.as_json}"
            # back to the view the link was in
            format.html { redirect_to(:back, notice: result[:message]) }
            format.json {render :json=>{ :success => result[:success] , :message=> result[:message], :lab_user => @labuser.id , :end_time => @labuser.end}}
          else
            format.html { redirect_to :back , :notice=> "Can't find lab user" }
            format.json { render :json=> {:success => false , :message=>  "Can't find lab user" }}
          end
        else
          format.html { redirect_to :back , :notice=> 'No such user' }
          format.json { render :json=> {:success => false , :message=>  'No such user' }}
        end  
      else
        format.html { redirect_to :back , :notice=> 'Restricted access' }
        format.json { render :json=> {:success => false , :message=>  'No permission error' }}
      end
    end
    rescue ActionController::RedirectBackError # cant redirect back? go to the lab instead
      logger.info "\nNo :back error\n"
      redirect_to(my_labs_path)
  end

  #method for ending a lab, deletes virtual machine db rows and sets the end date for the lab
  def end_lab
    respond_to do |format|
      @lab_user=LabUser.find(params[:id]) #NB! not based on lab, but based on attempt!
      if current_user==@lab_user.user || @admin #check if this is this users lab (to not allow url hacking) or if the user is admin
        logger.debug "\nEnding '#{@lab_user.user.username}' lab '#{@lab_user.lab.name}' as admin\n" if @admin
        # remove the vms for this lab_user
        result = @lab_user.end_lab
        logger.debug "mission #{@lab_user.id} end result: #{result.as_json}"
        # back to the view the link was in
        format.html { redirect_to(:back, notice: result[:message]) }
        format.json {render :json=>{ :success => result[:success] , :message=> result[:message], :lab_user => @lab_user.id , :end_time => @lab_user.end}}
      else #this lab doesnt belong to this user, permission error
        format.html { redirect_to error_401_path , :notice=> 'Restricted access!' }
        format.json {render :json=>{ :success => false , :message=> 'No permission error' }}
      end # end- this users lab
    end
    rescue ActiveRecord::RecordNotFound
      respond_to do |format|
        format.html { redirect_to my_labs_path, :notice => 'Can not find users lab!' }
        format.json { render :json=>{:success => false, :message=> 'can not find users lab' }}
      end
    rescue ActionController::RedirectBackError # cant redirect back? go to the lab instead
      logger.info '\nNo :back error\n'
      redirect_to(my_labs_path+(@lab_user.lab ? "/#{@lab_user.lab.id}" : ''))
  end
  

  def restart_lab_by_id
    respond_to do |format|
      if @admin && params[:labuser_id]
        @labuser= LabUser.where('id=?', params[:labuser_id]).first
        if @labuser
          result = @labuser.restart_lab
          # back to the view the link was in
          format.html { redirect_to(:back, notice: result[:message]) }
          format.json {render :json=>{ :success => result[:success] , :message=> result[:message], :lab_user => @labuser.id, :start_time => @labuser.start }}
        else
          format.html { redirect_to :back , :notice=> "Can't find lab user" }
          format.json { render :json=> {:success => false , :message=>  "Can't find lab user" }}
        end
      else
        format.html { redirect_to :back , :notice=> 'Restricted access' }
        format.json { render :json=> {:success => false , :message=>  'No permission error' }}
      end
    end
    rescue ActionController::RedirectBackError # cant redirect back? go to the lab instead
      logger.info "\nNo :back error\n"
      redirect_to(my_labs_path)
  end

  # Restarting a lab means deleting virtual machines and removing start/end times
  def restart_lab
    respond_to do |format|
      @lab=Lab.find(params[:id])
      get_user
      if !@user 
        logger.debug "Can't find user: "
        logger.debug params
        format.html { redirect_to :back , :notice=> "Can't find user" }
        format.json { render :json=> {:success => false , :message=>  "Can't find user" }}
      elsif !@admin && (params[:username] || params[:user_id])
        user = params[:username] ? params[:username] : params[:user_id]
        logger.debug "\nuser '#{current_user.username}' tried to load '#{user}' lab and was redirected to own lab\n"
        # simple user should not have the username in url
        format.html { redirect_to(my_labs_path+(params[:id] ? "/#{params[:id]}" : ''))}
        format.json { render :json=>{:success => false , :message=> 'No permission error' }}
      else
        @lab_user=LabUser.where('lab_id=? and user_id=?', @lab.id, @user.id).last
        if @lab_user!=nil
          logger.debug "\nRestarting '#{@lab_user.user.username}' lab '#{@lab_user.lab.name}' as admin\n" if @admin
          # restart lab (stop ->  clear -> start)
          result = @lab_user.restart_lab
          # redirect back to the view the link was in
          format.html { redirect_to(:back, notice: result[:message]) }
          format.json {render :json=>{ :success => result[:success] , :message=> result[:message], :lab_user => @lab_user.id, :start_time => @lab_user.start }}
        else # no this user does not have this lab
          format.html { redirect_to my_labs_path, :notice => 'That lab was not assigned to this user!' }
          format.json { render :json=>{:success => false, :message=> 'That lab was not assigned to this user!' }}
        end
      end
    end
    rescue ActiveRecord::RecordNotFound
      respond_to do |format|
        logger.debug "Can't find lab: "
        logger.debug params
        format.html { redirect_to my_labs_path , :notice=> "Can't find lab" }
        format.json { render :json=> {:success => false , :message=>  "Can't find lab" }}
      end
    rescue ActionController::RedirectBackError # cant redirect back? go to the lab instead
      logger.info "\nNo :back error\n"
      redirect_to(my_labs_path+(@lab ? "/#{@lab.id}" : '')+(@lab && params[:username] ? "/#{params[:username]}" : ''))
  end
  

  private #----------------------------------------------------------------------------------
   def get_user_labs(user)
    @labs=[] #only let the users pick from labs assigned to them
    @started=[]
    @complete=[]
    @not_started=[]
    #categorize the labs, order: running, not started, ended
    labusers=LabUser.order("#{LabUser.connection.quote_column_name 'end'} desc, #{LabUser.connection.quote_column_name 'start'} desc").where('user_id=?', user.id)
    labusers.each do |u|
      @labs<<u.lab        
      @started<<u.lab  if u.start && !u.end 
      @complete<<u.lab  if u.start && u.end 
    end 
    @not_started=@labs-@started-@complete
  end
  
  def get_user
    @user=current_user # by default get the current user
    if  @admin  #  admins can use this to view users labs
      if params[:username]  # if there is a username in the url
        @user = User.where('username = ?',params[:username]).first
      end
      if params[:user_id]  # if there is a user_id in the url
        @user = User.where('id = ?',params[:user_id]).first
      end
    end
  end
end

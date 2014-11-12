class LabsController < ApplicationController  
  #users can see courses, running labs and end their OWN lab
  before_filter :authorise_as_admin, :except => [:labs, :start_lab, :end_lab, :restart_lab]

  #redirect to index view when trying to see unexisting things
  before_filter :save_from_nil, :only=>[:show, :edit, :update]
  # set the menu tab to show the user
  before_filter :course_tab, :only=>[:labs]
  before_filter :admin_tab, :except=>[:labs]
    
  
  def save_from_nil
    @lab = Lab.find_by_id(params[:id])
    if @lab==nil 
      redirect_to(labs_path,:notice=>"invalid id.")
    end
  end
  
  # GET /labs
  # GET /labs.xml
  def index
    @labs = Lab.paginate(:page=>params[:page], :per_page=>10)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @labs }
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
    @all_users=false
    @user_count=0
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @lab }
    end
  end

  # GET /labs/1/edit
  def edit
    #@lab = Lab.find(params[:id])
    @all_users=false
    all_users=all_lab_users
    @user_count=0;
    @user_count=all_users.count if all_users!=nil 
    @all_users=true if User.all.count==@user_count
  end

  def all_lab_users
    return LabUser.find(:all, :conditions=>["lab_id=?", @lab.id])
  end
  
  def add_all_users
    User.all.each do |u|
      l=LabUser.new
      l.lab_id=@lab.id
      l.user_id=u.id
      l.save if LabUser.find(:first, :conditions=>["lab_id=? and user_id=?", l.lab_id, l.user_id])==nil
    end
  end
  
  def remove_all_users
    all_lab_users.each do |u|
      u.destroy
    end
  end
  
  # POST /labs
  # POST /labs.xml
  def create
    @lab = Lab.new(params[:lab])
    @all_users=false
    @user_count=0
    respond_to do |format|
      if @lab.save
                
        add_all_users  if params[:add].to_s==1.to_s
                
        remove_all_users if params[:remove].to_s==1.to_s 
                
        format.html { redirect_to(@lab, :notice => "Lab was successfully created. #{params[:add]}") }
        format.xml  { render :xml => @lab, :status => :created, :location => @lab }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @lab.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /labs/1
  # PUT /labs/1.xml
  def update
    @lab = Lab.find(params[:id])
    
    @all_users=false
    all_users=all_lab_users
    @user_count=0;
    @user_count=all_users.count if all_users!=nil 
    @all_users=true if User.all.count==@user_count
    
    respond_to do |format|
      if @lab.update_attributes(params[:lab])
          
        add_all_users  if params[:add].to_s==1.to_s
                
        remove_all_users if params[:remove].to_s==1.to_s 
        
        format.html { redirect_to(@lab, :notice => 'Lab was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @lab.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /labs/1
  # DELETE /labs/1.xml
  def destroy
    @lab = Lab.find(params[:id])
    @lab.destroy

    respond_to do |format|
      format.html { redirect_to(labs_url) }
      format.xml  { head :ok }
    end
  end

# search for labs to end all of their attempts (lab_users) etc.
 def search

 end

  # view and do labs - user view
  def labs
    get_user # @user - either lab owner or current user
    if !@user && params[:username] then
          logger.debug "There is no user named '#{params[:username]}'"
          flash[:notice] = "There is no user named '#{params[:username]}'"
          redirect_to :back and return
    elsif !@admin && params[:username] then # simple user should not have the username in url
      logger.debug "\nmy_labs: Relocate user\n"
      # simple user should not have the username in url
      redirect_to(my_labs_path+(params[:id] ? "/#{params[:id]}" : ""))
    else
      get_user_labs(@user) # @labs (all labs), @started, @complete, @not_started
      # if no course is selected show the first one
      if params[:id]!=nil then
        @lab = Lab.find(params[:id])
      else
        @lab=@labs.first 
      end
      # to avoid users from seeing labs, that arent for them
      if !@labs.include?(@lab) && @labs!=[] then
        logger.debug "\n'#{current_user.username}' redirected: dont have lab '#{@lab.name}' (#{@lab.id}) \n"
        redirect_to(error_401_path) and return
      else
        @lab_user = LabUser.find(:last, :conditions=>["lab_id=? and user_id=?", @lab.id, @user.id]) if @lab
      end
    end

    rescue ActiveRecord::RecordNotFound
      redirect_to(my_labs_path) and return
    rescue ActionController::RedirectBackError # cant redirect back? go to the lab instead
      logger.info "\nNo :back error\n"
      redirect_to(my_labs_path+(params[:id] ? "/#{params[:id]}" : ""))
  end
  

  # method for starting a lab, creates virtual machine dbrows and sets the start time for the lab
  def start_lab
    @lab=Lab.find(params[:id])  
    get_user # @user - either lab owner or current user
    if !@user && params[:username] then
      logger.debug "There is no user named '#{params[:username]}'"
      flash[:notice] = "There is no user named '#{params[:username]}'"
      redirect_to :back and return
    elsif !@admin && params[:username] then
      logger.debug "\n start_lab: Relocate user\n"
      # simple user should not have the username in url
      redirect_to(my_labs_path+(params[:id] ? "/#{params[:id]}" : ""))
    else 
      # ok, there is such lab, but does the user have it?
      @lab_user = LabUser.find(:last, :conditions=>["lab_id=? and user_id=?", @lab.id, @user.id]) 
      if @lab_user!=nil then       # yes, this user has this lab
        logger.debug "\nStarting '#{@lab_user.user.username}' lab '#{@lab_user.lab.name}' as admin\n" if @admin
        # generating vm info if needed
        @lab_user.start_lab
      else
        # no this user does not have this lab
        flash[:alert] = "That lab was not assigned to you!"
        redirect_to(my_labs_path)
      end
      # what is done is done, redirect the user back to view the lab
      redirect_to :back
    end #is ok
    rescue ActiveRecord::RecordNotFound # if find cant find
      redirect_to(my_labs_path)
    rescue ActionController::RedirectBackError # cant redirect back? go to the lab instead
      logger.info "\nNo :back error\n"
      redirect_to(my_labs_path+(@lab ? "/#{@lab.id}" : "")+(@lab && params[:username] ? "/#{params[:username]}" : ""))
  end
  
  #method for ending a lab, deletes virtual machine db rows and sets the end date for the lab
  def end_lab
    @lab_user=LabUser.find(params[:id]) #NB! not based on lab, but based on attempt!
    #check if this is this users lab (to not allow url hacking) or if the user is admin
    if current_user==@lab_user.user || @admin then
      logger.debug "\nEnding '#{@lab_user.user.username}' lab '#{@lab_user.lab.name}' as admin\n" if @admin
      # remove the vms for this lab_user
      @lab_user.end_lab
      # back to the view the link was in
      redirect_to :back
    else #this lab doesnt belong to this user, permission error
      flash[:alert]  = "Restricted access!"
      redirect_to(error_401_path)
    end # end- this users lab
    rescue ActiveRecord::RecordNotFound
      redirect_to(my_labs_path)
    rescue ActionController::RedirectBackError # cant redirect back? go to the lab instead
      logger.info "\nNo :back error\n"
      redirect_to(my_labs_path+(@lab_user.lab ? "/#{@lab_user.lab.id}" : ""))
  end
  
  #restarting a lab means deleting virtual machines, removing start/end times and progress/results
  def restart_lab
    @lab=Lab.find(params[:id])
    get_user
    if !@user && params[:username] then
          logger.debug "There is no user named '#{params[:username]}'"
          flash[:notice] = "There is no user named '#{params[:username]}'"
          redirect_to :back and return
    elsif !@admin && params[:username] then
      logger.debug "\nuser '#{current_user.username}' tried to load '#{params[:username]}' lab and was redirected to own lab\n"
      # simple user should not have the username in url
      redirect_to(my_labs_path+(params[:id] ? "/#{params[:id]}" : ""))
    else
      @lab_user=LabUser.where("lab_id=? and user_id=?", @lab.id, @user.id).first
      if @lab_user!=nil then
        logger.debug "\nRestarting '#{@lab_user.user.username}' lab '#{@lab_user.lab.name}' as admin\n" if @admin
        # restart lab (stop ->  clear -> start)
        @lab_user.restart_lab
      else # no this user does not have this lab
        flash[:alert]  = "That lab was not assigned to you!"
        redirect_to(my_labs_path)
      end
      # redirect back to the view the link was in
      redirect_to :back
    end
    rescue ActiveRecord::RecordNotFound
      redirect_to(my_labs_path)
    rescue ActionController::RedirectBackError # cant redirect back? go to the lab instead
      logger.info "\nNo :back error\n"
      redirect_to(my_labs_path+(@lab ? "/#{@lab.id}" : "")+(@lab && params[:username] ? "/#{params[:username]}" : ""))
  end
  

  private #----------------------------------------------------------------------------------
   def get_user_labs(user)
    @labs=[] #only let the users pick from labs assigned to them
    @started=[]
    @complete=[]
    @not_started=[]
    #categorize the labs, order: running, not started, ended
    labusers=LabUser.find(:all, :conditions=>["user_id=?", user.id], :order => 'end ASC, start DESC')
    labusers.each do |u|
      @labs<<u.lab        
      @started<<u.lab  if u.start!=nil && u.end==nil 
      @complete<<u.lab  if u.start!=nil && u.end!=nil 
    end 
    @not_started=@labs-@started-@complete
  end
  
  def get_user
    @user=current_user # by default get the current user
    if params[:username] then # if there is a user_id in the url
      if  @admin then #  admins can use this to view users labs
        @user = User.where("username = ?",params[:username]).first 
      end
    end
  end
end
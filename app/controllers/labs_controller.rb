class LabsController < ApplicationController  
  #users can see courses, running labs and end their OWN lab
  before_filter :authorise_as_admin, :except => [:courses, :running_lab,:ended_lab, :end_lab, :restart_lab]

      #redirect to index view when trying to see unexisting things
  before_filter :save_from_nil, :only=>[:show, :edit, :update]
  # set the menu tab to show the user
  before_filter :course_tab, :only=>[:courses, :running_lab, :ended_lab]
  before_filter :admin_tab, :except=>[:courses, :running_lab, :ended_lab]
  
  def save_from_nil
    @lab = Lab.find_by_id(params[:id])
    if @lab==nil 
      redirect_to(labs_path,:notice=>"invalid id.")
    end
  end
  
  # GET /labs
  # GET /labs.xml
  def index
    @labs = Lab.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @labs }
    end
  end

  # GET /labs/1
  # GET /labs/1.xml
  def show
    #@lab = Lab.find(params[:id])

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
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @lab }
    end
  end

  # GET /labs/1/edit
  def edit
    #@lab = Lab.find(params[:id])
    @all_users=false
    @user_count=all_lab_users.count
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

  #view of labs that can be started/continued/viewed
  def courses
    
    get_user_labs
      
    # if no course is selected show the first one
    if params[:id]!=nil then
      @lab = Lab.find(params[:id])
    else
      @lab=@labs.first 
    end
     
   # to avoid users from seeing labs, that arent for them
    if !@labs.include?(@lab) && @labs!=[] then
     redirect_to(error_401_path)
    end
    rescue ActiveRecord::RecordNotFound
      redirect_to(courses_path)
  end
  
  def ended_lab
     get_user_labs
    @lab=Lab.find_by_id(params[:id])
     if @lab==nil 
      @lab=@complete.first
    end
    @other=@complete  
    
    @lab_user = LabUser.find(:last, :conditions=>["lab_id=? and user_id=?", @lab.id, current_user.id]) if @lab!=nil
    @note=""
    
    if @lab_user==nil && @lab!=nil
    #the lab is not meant for this user, redirect
    redirect_to(error_401_path)
    end
   render :action=>"running_lab"
   rescue ActiveRecord::RecordNotFound
    redirect_to(courses_path)      
  end
  
  
  #view for running or completed labs
  def running_lab
    get_user_labs
    @lab=Lab.find_by_id(params[:id])
    
    if @lab==nil 
      @lab=@started.first
    end
    @other=@started
    #find the last appearance of the current users lab (repeating a lab made possible)
    @lab_user = LabUser.find(:last, :conditions=>["lab_id=? and user_id=?", @lab.id, current_user.id]) if @lab!=nil
    @note=""
    @vms=[]
    
    if @lab_user!=nil then #this user has this lab
    # generating vm info if needed
    @lab_user.lab.lab_vmts.each do |template|
      #is there a machine like that already?
      vm=Vm.find(:first, :conditions=>["lab_vmt_id=? and user_id=?", template.id, current_user.id ])
      if vm==nil then
        #no there is not
        v=Vm.new
        v.name="#{template.name}-#{current_user.username}"
        v.lab_vmt_id=template.id
        v.user_id=current_user.id
        
        
        #vm description TODO add login info
        v.description="Initialize the virtual machine by clicking <strong>Start</strong>."
        
        
        
        v.save
        @note="Machines successfully generated."
        @vms<<v
      else
        @vms<<vm
      end
    end #end of making vms based of templates
    if @lab_user.start==nil then
      @lab_user.start=Time.now
      @lab_user.save
      #first time access to the lab
      @status="running"
      @other=@other+@started
    end
  else
    #the lab is not meant for this user, redirect
    redirect_to(error_401_path) if @lab!=nil
  end
  
   rescue ActiveRecord::RecordNotFound
      redirect_to(courses_path)
  end
  
  #method for ending a lab, deletes virtual machine db rows and sets the end date for the lab
  def end_lab
    @lab_user=LabUser.find(params[:id])
    @note=""
    #check if this is this users lab (to not allow url hacking)
    if current_user==@lab_user.user 
      @lab_user.lab.lab_vmts.each do |template|
        template.vms.each do |t|
        if t.user==current_user
          t.destroy
          @note="Machines successfully deleted."
        end
      end
    end #end of deleting vms for this lab
     if @note!="" then
        @lab_user.end=Time.now
        @lab_user.save
     end
    redirect_to(ended_courses_path+"/"+@lab_user.lab.id.to_s)
  else #this lab doesnt belong to this user, permission error
    flash[:alert]  = "Restricted access!"
    redirect_to(error_401_path)
  end # end- this users lab
  
  rescue ActiveRecord::RecordNotFound
    redirect_to(courses_path)
  end
  
  #restarting a lab means deleting virtual machines, removing start/end times and progress/results
  def restart_lab
    @lab=Lab.find(params[:id])
    @lab_user=LabUser.find(:last, :conditions=>["lab_id=? and user_id=?", @lab.id, current_user.id])
    if @lab_user!=nil 
     @lab_user.update_attributes(:progress =>nil, :result =>nil, :start=>nil, :pause=>nil, :end=>nil) 
    
    @lab_user.lab.lab_vmts.each do |template|
    template.vms.each do |t|
      if t.user==current_user
        t.destroy
        @note="Machines successfully deleted."
      end
     end
    end
        
  end
     redirect_to(running_courses_path+"/"+@lab.id.to_s)
  rescue ActiveRecord::RecordNotFound
    redirect_to(courses_path)
  end
  
  private #----------------------------------------------------------------------------------
   def get_user_labs
    @labs=[] #only let the users pick from labs assigned to them
    @started=[]
    @complete=[]
    #categorize the labs
    labusers=LabUser.find(:all, :conditions=>["user_id=?", current_user.id], :order => 'end ASC, start ASC')
    labusers.each do |u|
      @labs<<u.lab        
      @started<<u.lab  if u.start!=nil && u.end==nil 
      @complete<<u.lab  if u.start!=nil && u.end!=nil 
    end 
  end
  
end
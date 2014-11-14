# encoding: utf-8
class VmsController < ApplicationController
before_filter :authorise_as_admin, :only => [:new, :edit ]
  
  #before_filter :authorise_as_admin, :except => [:show, :index, :init_vm, :stop_vm, :pause_vm, :resume_vm, :start_vm, :start_all]
  #redirect to index view when trying to see unexisting things
  before_filter :save_from_nil, :only=>[:show, :edit, :start_vm, :stop_vm, :pause_vm, :resume_vm]
  before_filter :auth_as_owner, :only=>[:show, :start_vm, :stop_vm, :pause_vm, :resume_vm]       
  
  before_filter :admin_tab, :except=>[:show,:index, :vms_by_lab, :vms_by_state]
  before_filter :vm_tab, :only=>[:show,:index, :vms_by_lab, :vms_by_state]
  def save_from_nil
    @vm = Vm.find_by_id(params[:id])
    if @vm==nil 
      redirect_to(vms_path,:notice=>"invalid id.")
    end
  end
  
  def vms_by_lab
    @b_by="lab"
    sql=[]
    if params[:dir]=="asc" then
      dir = "ASC"
      @dir = "&dir=desc"
    else 
      dir = "DESC"
      @dir = "&dir=asc"
    end
    order = params[:sort_by]!=nil ? " order by #{params[:sort_by]} #{dir}" : ""
    logger.debug "ORDER #{order}"
    if params[:admin]!=nil && @admin then
      @lab=Lab.find(params[:id]) if params[:id]# try to get the selected lab
      @lab=Lab.first if !params[:id] # but if the parameter is not set, take the first lab
      #@vms=Vm.find(:all, :joins=>["vms inner join lab_vmts as l on vms.lab_vmt_id=l.id"], :order=>params[:sort_by])
      sql= Vm.find_by_sql("select vms.*, lab_vmts.lab_id from vms, lab_vmts where vms.lab_vmt_id=lab_vmts.id and lab_id=#{@lab.id} #{order}")
      @tab="admin"
      @labs=Lab.find(:all).uniq
    else
      if params[:id]!=nil then # try to get the selected lab 
         @lab=Lab.find(:first, :joins=>["labs inner join lab_users on lab_users.lab_id=labs.id"], :conditions=>["lab_id=? and user_id=?",params[:id], current_user.id])
      else # but if the parameter is not set, take the first lab this user has   
         @lab=Lab.find(:first, :joins=>["labs inner join lab_users on lab_users.lab_id=labs.id"], :conditions=>["user_id=?", current_user.id])  
      end
       sql= Vm.find_by_sql("select * from vms, lab_vmts where vms.lab_vmt_id=lab_vmts.id and lab_id=#{@lab.id} and user_id=#{current_user.id} #{order}") if @lab # only try to get the vms if there is a lab
      @labs=Lab.find(:all, :joins=>["labs inner join lab_users on lab_users.lab_id=labs.id"], :conditions=>["user_id=?", current_user.id]).uniq
    end
    @vms= sql.paginate( :page => params[:page], :per_page => 10)
    render :action=>'index'
  end
  
   def vms_by_state
    @b_by="state"
    @state="running"
    @state=params[:state] if params[:state]
    state=@state
    state="error:" if state=="uninitialized"
    # TODO! turn it into DRY
    if params[:dir]=="asc" then
      dir = "ASC"
      @dir = "&dir=desc"
    else 
      dir = "DESC"
      @dir = "&dir=asc"
    end
    order = params[:sort_by] ? " order by #{params[:sort_by]} #{dir}" : ""
  
    if params[:admin]!=nil && @admin then
      @tab="admin"
      vms=Vm.find_by_sql("select vms.*, lab_vmts.lab_id from vms, lab_vmts where vms.lab_vmt_id=lab_vmts.id #{order}")
    else
       vms=Vm.find_by_sql("select vms.*, lab_vmts.lab_id from vms, lab_vmts where vms.lab_vmt_id=lab_vmts.id and user_id=#{current_user.id} #{order}")    
    end
    @vm=[]
    vms.each do |vm|
      @vm.push(vm) if vm.state==state
    end
    @vms=@vm.paginate(:page=>params[:page], :per_page=>10)
    render :action=>'index'
  end
  
  # GET /vms
  # GET /vms.xml
  def index
    if params[:dir]=="asc" then
      dir = "ASC"
      @dir = "&dir=desc"
    else 
      dir = "DESC"
      @dir = "&dir=asc"
    end
    order = params[:sort_by] ? " order by #{params[:sort_by]} #{dir}" : ""

    if params[:admin]!=nil && @admin then
      sql= "select vms.*, lab_vmts.lab_id from vms, lab_vmts where vms.lab_vmt_id=lab_vmts.id #{order}"
      @tab="admin"
    else  
      sql= "select vms.*, lab_vmts.lab_id from vms, lab_vmts where vms.lab_vmt_id=lab_vmts.id and user_id=#{current_user.id} #{order}"
    end
    @vms= Vm.paginate_by_sql(sql, :page => params[:page], :per_page => 10)
    
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @vms }
    end
  end

  # GET /vms/1
  # GET /vms/1.xml
  def show
   # @vm = Vm.find(params[:id])
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @vm }
    end
  end

  # GET /vms/new
  # GET /vms/new.xml
  def new
    @vm = Vm.new
    
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @vm }
    end
  end

  # GET /vms/1/edit
  def edit
    #@vm = Vm.find(params[:id])
  end

  
  # POST /vms
  # POST /vms.xml
  def create
    @vm = Vm.new(params[:vm])
  
    respond_to do |format|
      if @vm.save
        format.html { redirect_to(vms_path+"?admin=1", :notice => 'Vm was successfully created.') }
        format.xml  { render :xml => @vm, :status => :created, :location => @vm }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @vm.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /vms/1
  # PUT /vms/1.xml
  def update
    @vm = Vm.find(params[:id])

    respond_to do |format|
      if @vm.update_attributes(params[:vm])
        format.html { redirect_to(vms_path+"?admin=1", :notice => 'Vm was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @vm.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /vms/1
  # DELETE /vms/1.xml
  def destroy
    @vm = Vm.find(params[:id])
    @vm.destroy

    respond_to do |format|
      format.html { redirect_to(vms_path+"?admin=1") }
      format.xml  { head :ok }
    end
  end

  #start all the machines this user has in a given lab
  def start_all
    @lab=Lab.find_by_id(params[:id])
    @user=current_user
    if params[:username] && @admin then
      @user = User.where("username = ?",params[:username]).first 
      @user = curent_user unless @user # in case of mistyped username 
    end

    @labuser = LabUser.find(:last, :conditions=>["lab_id=? and user_id=?", @lab.id, @user.id]) if @lab!=nil
    redirect = :back
    if (@labuser == nil && @lab!=nil) || @lab==nil #either the lab doesnt exist or the user doesnt have it
      redirect=error_401_path
    end
    if @labuser!=nil #user has this lab
      flash[:notice]=""

      @labuser.vms.each do |vm|
        if vm.state!="running" && vm.state!="paused" then # cant be running nor paused
          @a = vm.start_vm 
          logger.info vm.name
          flash[:notice]=flash[:notice]+@a[:notice]+"<br/>"
        end #end if not running or paused
      end #end iterate trough vms
    end#end if labuser
    flash[:notice]=flash[:notice].html_safe
    redirect_to(redirect)

  rescue Timeout::Error
    flash[:alert]="<br/>Starting all virtual machines failed, try starting them one by one."
    flash[:notice]=nil
    redirect_to(:back)

    rescue ActionController::RedirectBackError # cant redirect back? go to the lab instead
      logger.info "\nNo :back error\n"
      redirect_to(my_labs_path+"/"+@lab.id.to_s)

    end
  
  #start one machine
  def start_vm
    result = @vm.start_vm
    flash[:notice] = result[:notice].html_safe if result[:notice]!=""
    flash[:alert] = result[:alert].html_safe if result[:alert]!=""
    redirect_to(:back)
    rescue ActionController::RedirectBackError  # cant redirect back? go to the lab instead
      logger.info "\nNo :back error\n"
      redirect_to(my_labs_path+"/"+@vm.lab_vmt.lab.id.to_s)
  end
  
  #resume machine from pause
  def resume_vm
    #@vm=Vm.find(params[:id])
    flash[:notice] = @vm.resume_vm 
    redirect_to(:back)
  end
  
  #pause a machine
  def pause_vm
    #@vm=Vm.find(params[:id])
    flash[:notice] = @vm.pause_vm.html_safe
    redirect_to(:back) 
  end
  
  #stop the machine, do not delete the vm row from the db (release mac, but allow reinitialization)
  def stop_vm
    #@vm=Vm.find(params[:id])
    flash[:notice] = @vm.stop_vm
    redirect_to(:back)
  end
  
  #this is a method that updates a vms progress
  #input parameters: ip (the machine, the report is about)
  #           progress (the progress for the machine)
  def set_progress
    #who sent the info? 
    @client_ip = request.remote_ip
    @remote_ip = request.env["HTTP_X_FORWARDED_FOR"]
    
    #get the vms based on the ip aadress and update the vm.progress based on the input
    @target_ip=params[:ip]
    if @target_ip==nil then 
      @target_ip="error" 
    else
      #check if the param was actually in a form of a ip
      @check=@target_ip.split('.')
      if @target_ip==@client_ip && ((Integer(@check[0]) rescue nil) && (Integer(@check[1]) rescue nil) && (Integer(@check[2]) rescue nil) && (Integer(@check[3]) rescue nil)) then#TODO- once the allowed ip range is known, update
        @progress=params[:progress]
        if @progress!=nil then
          @progress.gsub!(/_/) do
            "<br/>"
          end
        end
        @mac=Mac.find(:first, :conditions=>['ip=?', @target_ip])
        @vm=@mac.vm
        if @vm!=nil then
          #the mac exists and has a vm
          @vm.progress=@progress
          @vm.save() 
        end#end vm exists        
      end#end the target sent the progress
    end#end the ip parameter is set
  end
   
  def get_progress
    
    @vm=Vm.find_by_id(params[:id])
    unless @vm || @vm.user.id==current_user.id || @admin then 
      @vm=Vm.new #dummy
    end
    render :partial => 'shared/vm_progress' 
  end
  
   #redirect user if they are not admin or the machine owner but try to modify a machine
  def auth_as_owner
    #@vm=Vm.find(params[:id])
    #is this vm this users?
    unless current_user==@vm.user || @admin
      #You don't belong here. Go away.
      flash[:notice]  = "Sorry, this machine doesnt belong to you!"
      redirect_to(vms_path)
    end
  end

end

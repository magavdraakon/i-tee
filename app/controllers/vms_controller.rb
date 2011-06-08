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
    
    if params[:admin]!=nil && @admin then
     @vms = Vm.all 
    @tab="admin"
    else
      #@vms=Vm.find(:all, :conditions=>["user_id=?",current_user])
      @vms=current_user.vms
    end
    @labs=[]
    @vms.each do |vm|
      @labs<< vm.lab_vmt.lab
    end
    @labs.uniq!
    render :action=>'index'
  end
  
   def vms_by_state
    @b_by="state"
    if params[:admin]!=nil && @admin then
     @vms = Vm.all 
     @tab="admin"
    else
      #@vms=Vm.find(:all, :conditions=>["user_id=?",current_user])
      @vms=current_user.vms
    end
    
    render :action=>'index'
  end
  
  # GET /vms
  # GET /vms.xml
  def index
    if params[:admin]!=nil && @admin then
     @vms = Vm.all 
     @tab="admin"
    else
      #@vms=Vm.find(:all, :conditions=>["user_id=?",current_user])
      @vms=current_user.vms
    end
        
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
    @labuser=LabUser.find(:last, :conditions=>["lab_id=? and user_id=?", @lab.id, current_user.id]) if @lab!=nil
    redirect=:back
    if (@labuser==nil && @lab!=nil) || @lab==nil #either the lab doesnt exist or the user doesnt have it
      redirect=error_401_path
    end
    if @labuser!=nil #user has this lab
      flash[:notice]=""
      
      current_user.vms.each do |vm|
        if vm.lab_vmt.lab.id==@lab.id && (vm.state!="running" || vm.state!="paused")
          init_vm(vm) 
          logger.info vm.name
        
          require 'timeout'
          status = Timeout::timeout(60) {
            # Something that should be interrupted if it takes too much time...
            if @a!=nil
            until @a.include?("masin #{vm.name} loodud")
            #do nothing, just wait
            end
          end
          }
           flash[:notice]=flash[:notice]+"<br/>"
        end #end if right lab
      end #end iterate trough vms
    end#end if labuser
    redirect_to(redirect)
    rescue Timeout::Error
      flash[:alert]="Starting all virtual machines failed, try starting them one by one."
      flash[:notice]=""
      redirect_to(:back)
  end
  
  #start one machine
  def start_vm
     flash[:notice]=""
    init_vm(@vm)
  #  flash[:alert]=@a
    redirect_to(:back)
  end
  
  #assign mac and start machine
  def init_vm(vm)
    #@vm=Vm.find(params[:id])
     #find out if there is a mac address bound with this vm already
     @mac= Mac.find(:first, :conditions=>["vm_id=?", vm.id])
      # binding a unused mac address with the vm if there is no mac
     if @mac==nil then
       @mac= Mac.find(:first, :conditions=>["vm_id is null"])
        @mac.vm_id=vm.id
       if @mac.save  #save õnnestus, masinal on mac olemas..
        flash[:notice] = flash[:notice]+"successful mac assignement."#"Successful vm initialisation." 
      #  logger.info "käivitame masina skripti"
      # a=vm.ini_vm #the script is called in the model
      #logger.info a
        # redirect_to(:back)
        end #end -if save
      else
        #the vm had a mac already, dont do anything
       flash[:notice] = flash[:notice]+"Vm already had a mac."
        #redirect_to(:back)
      end # end if nil
      
      if vm.state!="running" && vm.state!="paused"
      logger.info "käivitame masina skripti"
        @a=vm.ini_vm #the script is called in the model
        logger.info @a
       
        
        vm.description="machine #{@mac.mac} with IP address of #{@mac.ip}<br/>Create a connection with this machine using <strong>ssh #{vm.lab_vmt.vmt.username}@#{@mac.ip}</strong><br/>The set password for this machine is <strong>#{vm.password}</strong>"
        vm.save
       
        if @a.include?("masin #{vm.name} loodud")
         flash[:notice]=flash[:notice]+"<br/>"+vm.description
        else  
          flash[:notice]=""
         flash[:alert]="machine initialization failed."
        end
      end
      
      #VAADATA ÜLE!!!
    rescue ActiveRecord::StaleObjectError # to resque from conflict, go on a new round of init?
      logger.info "Mac address conflict"
      redirect_to(:action=>'start_vm', :id=>vm.id)
  end
  
  #resume machine from pause
  def resume_vm
    #@vm=Vm.find(params[:id])
      logger.info "käivitame masina taastamise skripti"
      a=@vm.res_vm # the script is called in the model
      flash[:notice] = "Successful vm resume." 
      logger.info a
      redirect_to(:back)
  end
  
  #pause a machine
  def pause_vm
    #@vm=Vm.find(params[:id])
      logger.info "käivitame masina pausimise skripti"
      a=@vm.pau_vm #the script is called in the model
      
      flash[:notice] = "Successful vm pause.<br/> To resume the machine click on the resume link next to the machine name." 
      logger.info a
      redirect_to(:back) 
  end
  
  #stop the machine, do not delete the vm row from the db (release mac, but allow reinitialization)
  def stop_vm
    #@vm=Vm.find(params[:id])
      logger.info "käivitame masina sulgemise skripti"
      a=@vm.del_vm #the script is called in the model
      logger.info a
      @vm.description="Initialize the virtual machine by clicking <strong>Start</strong>."
      @vm.save
      flash[:notice] = "Successful vm deletion." 
      @mac= Mac.find(:first, :conditions=>["vm_id=?", @vm.id])
      @mac.vm_id=nil
      @mac.save
      redirect_to(:back)
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

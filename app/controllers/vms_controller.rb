class VmsController < ApplicationController

  before_filter :authorise_as_admin, :except => [:show, :index,:init_vm, :stop_vm, :pause_vm, :resume_vm]

  # GET /vms
  # GET /vms.xml
  def index
    if @admin then
    @vms = Vm.all 
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
    @vm = Vm.find(params[:id])
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @vm }
    end
  end

  # GET /vms/new
  # GET /vms/new.xml
  def new
    @vm = Vm.new
    @templates=LabVmt.all
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @vm }
    end
  end

  # GET /vms/1/edit
  def edit
    @vm = Vm.find(params[:id])
    @templates=LabVmt.all
  end

  # POST /vms
  # POST /vms.xml
  def create
    @vm = Vm.new(params[:vm])

    respond_to do |format|
      if @vm.save
        format.html { redirect_to(@vm, :notice => 'Vm was successfully created.') }
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
        format.html { redirect_to(@vm, :notice => 'Vm was successfully updated.') }
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
      format.html { redirect_to(vms_url) }
      format.xml  { head :ok }
    end
  end

  
  
  
  #assign mac and start machine
  def init_vm
    @vm=Vm.find(params[:id])
    #is this vm this users?
    if current_user==@vm.user || @admin then
     #find out if there is a mac address bound with this vm already
     @mac= Mac.find(:first, :conditions=>["vm_id=?", @vm.id])
      # binding a unused mac address with the vm if there is no mac
     if @mac==nil then
       @mac= Mac.find(:first, :conditions=>["vm_id is null"])
        @mac.vm_id=@vm.id
       if @mac.save  #save õnnestus, masinal on mac olemas..
        flash[:notice] = "Successful vm initialisation." 
        logger.info "käivitame masina skripti"
        a=@vm.ini_vm #the script is called in the model
        logger.info a
         redirect_to(:back)
        end #end -if save
      else
        #the vm had a mac already, dont do anything
       flash[:notice] = "Vm already initialized."
        redirect_to(:back)
      end # end if nil
    else #not this users machine
      redirect_to(error_401_path)
    end
    rescue ActiveRecord::StaleObjectError # to resque from conflict, go on a new round of init?
      redirect_to(init_vm_path, :id=>@vm.id)
  end
  
  #resume machine from pause
  def resume_vm
    @vm=Vm.find(params[:id])
     #is this vm this users?
    if current_user==@vm.user || @admin then
      logger.info "käivitame masina taastamise skripti"
      a=@vm.res_vm # the script is called in the model
      flash[:notice] = "Successful vm resume." 
      logger.info a
      redirect_to(:back)
    else #not this users machine
      redirect_to(error_401_path)
    end
  end
  
  #pause a machine
  def pause_vm
    @vm=Vm.find(params[:id])
     #is this vm this users?
    if current_user==@vm.user || @admin then
      logger.info "käivitame masina pausimise skripti"
      a=@vm.pau_vm #the script is called in the model
      flash[:notice] = "Successful vm pause." 
      logger.info a
      redirect_to(:back) 
    else #not this users machine
      redirect_to(error_401_path)
    end
  end
  
  #stop the machine, do not delete the vm row from the db (release mac, but allow reinitialization)
  def stop_vm
    @vm=Vm.find(params[:id])
   #is this vm this users?
    if current_user==@vm.user || @admin then
      logger.info "käivitame masina sulgemise skripti"
      a=@vm.del_vm #the script is called in the model
      logger.info a
      flash[:notice] = "Successful vm deletion." 
      @mac= Mac.find(:first, :conditions=>["vm_id=?", @vm.id])
      @mac.vm_id=nil
      @mac.save
      redirect_to(:back)
     else #not this users machine
      redirect_to(error_401_path)
    end
  end
  
end

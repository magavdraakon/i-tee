class VmsController < ApplicationController
  layout 'main'
  before_filter :authorise_as_admin, :except => [:show, :index]

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
    @vm.state="started"
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
    #find out if there is a mac address bound with this vm already
    @mac= Mac.find(:first, :conditions=>["vm_id=?", @vm.id])
    # binding a unused mac address with the vm if there is no mac
    if @mac==nil then
      @mac= Mac.find(:first, :conditions=>["vm_id is null"])
      @mac.vm_id=@vm.id
      if @mac.save
       flash[:notice] = "Successful vm initialisation." 
        logger.info "käivitame masina skripti"
        #save õnnestus, masinal on mac olemas.. TODO: skripti käivitamine
        a=%x(/var/www/railsapps/i-tee/utils/start_machine.sh #{@vm.mac.mac} #{@vm.lab_vmt.vmt.image} #{@vm.name} 2>&1)
      
       logger.info a
       redirect_to(vms_url)
      end
    else
      #the vm had a mac already, dont do anything
      flash[:notice] = "Vm already initialized."
      redirect_to(vms_url)
    end
  rescue ActiveRecord::StaleObjectError # to resque from conflict, go on a new round of init?
    redirect_to(init_vm_path, :id=>@vm.id)
    
  end
  
  #resume machine from pause
  def resume_vm
    @vm=Vm.find(params[:id])
    #TODO @vm infoga resume skripti käivitamine
    logger.info "käivitame masina taastamise skripti"
    a=%x(/var/www/railsapps/i-tee/utils/resume_machine.sh #{@vm.name}  2>&1)
    flash[:notice] = "Successful vm resume." 
    logger.info a
    redirect_to(vms_url)
  end
  
  #pause a machine
  def pause_vm
    @vm=Vm.find(params[:id])
    #TODO @vm infoga pause skripti käivitamine
    logger.info "käivitame masina taastamise skripti"
    a=%x(/var/www/railsapps/i-tee/utils/pause_machine.sh #{@vm.name}  2>&1)
    flash[:notice] = "Successful vm pause." 
     logger.info a
    redirect_to(vms_url)
  end
  
  #stop the machine/delete it, delete the vm row from the db (release mac)
  def stop_vm
    @vm=Vm.find(params[:id])
    #TODO @vm infoga stop skripti käivitamine
    logger.info "käivitame masina taastamise skripti"
    a=%x(/var/www/railsapps/i-tee/utils/stop_machine.sh #{@vm.name}  2>&1)
    logger.info a
    flash[:notice] = "Successful vm deletion." 
    redirect_to(vms_url)
  end
  
end

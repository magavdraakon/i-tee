class VmsController < ApplicationController
  layout 'main'
  before_filter :authorise_as_admin, :except => [:show, :index]

  # GET /vms
  # GET /vms.xml
  def index
    @vms = Vm.all      
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

end

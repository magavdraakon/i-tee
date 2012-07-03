class OperatingSystemsController < ApplicationController
    before_filter :admin_tab
      #restricted to admins
   before_filter :authorise_as_admin
  
  # GET /operating_systems
  # GET /operating_systems.xml
  def index
    @operating_systems = OperatingSystem.paginate(:page=>params[:page], :per_page=>10)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @operating_systems }
    end
  end

  # GET /operating_systems/1
  # GET /operating_systems/1.xml
  def show
    @operating_system = OperatingSystem.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @operating_system }
    end
  end

  # GET /operating_systems/new
  # GET /operating_systems/new.xml
  def new
    @operating_system = OperatingSystem.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @operating_system }
    end
  end

  # GET /operating_systems/1/edit
  def edit
    @operating_system = OperatingSystem.find(params[:id])
  end

  # POST /operating_systems
  # POST /operating_systems.xml
  def create
    @operating_system = OperatingSystem.new(params[:operating_system])

    respond_to do |format|
      if @operating_system.save
        format.html { redirect_to(@operating_system, :notice => 'Operating system was successfully created.') }
        format.xml  { render :xml => @operating_system, :status => :created, :location => @operating_system }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @operating_system.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /operating_systems/1
  # PUT /operating_systems/1.xml
  def update
    @operating_system = OperatingSystem.find(params[:id])

    respond_to do |format|
      if @operating_system.update_attributes(params[:operating_system])
        format.html { redirect_to(@operating_system, :notice => 'Operating system was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @operating_system.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /operating_systems/1
  # DELETE /operating_systems/1.xml
  def destroy
    @operating_system = OperatingSystem.find(params[:id])
    @operating_system.destroy

    respond_to do |format|
      format.html { redirect_to(operating_systems_url) }
      format.xml  { head :ok }
    end
  end
end

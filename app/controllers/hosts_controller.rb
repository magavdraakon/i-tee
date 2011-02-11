class HostsController < ApplicationController
  layout 'main'

     before_filter :authorise_as_admin

  # GET /hosts
  # GET /hosts.xml
  def index
    @hosts = Host.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @hosts }
    end
  end

  # GET /hosts/1
  # GET /hosts/1.xml
  def show
    @host = Host.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @host }
    end
  end

  # GET /hosts/new
  # GET /hosts/new.xml
  def new
    @host = Host.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @host }
    end
  end

  # GET /hosts/1/edit
  def edit
    @host = Host.find(params[:id])
  end

  # POST /hosts
  # POST /hosts.xml
  def create
    @host = Host.new(params[:host])

    respond_to do |format|
      if @host.save
        format.html { redirect_to(@host, :notice => 'Host was successfully created.') }
        format.xml  { render :xml => @host, :status => :created, :location => @host }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @host.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /hosts/1
  # PUT /hosts/1.xml
  def update
    @host = Host.find(params[:id])

    respond_to do |format|
      if @host.update_attributes(params[:host])
        format.html { redirect_to(@host, :notice => 'Host was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @host.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /hosts/1
  # DELETE /hosts/1.xml
  def destroy
    @host = Host.find(params[:id])
    @host.destroy

    respond_to do |format|
      format.html { redirect_to(hosts_url) }
      format.xml  { head :ok }
    end
  end

  def machines
    @images = Host.new.getEycalyptusInstance.getImages
  end

  def instances
    @instances = Host.new.getEycalyptusInstance.getInstances
    @runningInstances = Host.new.getEycalyptusInstance.getRunningInstances
  end

  def getInstanceJSON
    @instances = Host.new.getEycalyptusInstance.getInstances

    @instances.each do |instance|
      if instance[:aws_instance_id] == params[:id]
        @inst = instance
        break
      end
    end

    render :json => @inst
  end

  def getImagesJSON
    @machineImages = Host.new.getEycalyptusInstance.getMachineImages

    render :json => @machineImages
  end

  def getUsersJSON
    @users = User.all(:select => "username")
    #@cities = City.find_by_state(:all)
    render :json => @users
  end

  def terminate
    Host.new.getEycalyptusInstance.terinateInstance(params[:id])

    redirect_to :action => "instances"
  end

  def run
    Host.new.getEycalyptusInstance.startInstance(params[:image], User.find_by_username(params[:user]))
    
    redirect_to :action => "instances"
  end

end

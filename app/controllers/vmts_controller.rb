class VmtsController < ApplicationController
  # GET /vmts
  # GET /vmts.xml
  before_filter :authorise_as_admin
  def index
    @vmts = Vmt.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @vmts }
    end
  end

  # GET /vmts/1
  # GET /vmts/1.xml
  def show
    @vmt = Vmt.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @vmt }
    end
  end

  # GET /vmts/new
  # GET /vmts/new.xml
  def new
    @vmt = Vmt.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @vmt }
    end
  end

  # GET /vmts/1/edit
  def edit
    @vmt = Vmt.find(params[:id])
  end

  # POST /vmts
  # POST /vmts.xml
  def create
    @vmt = Vmt.new(params[:vmt])

    respond_to do |format|
      if @vmt.save
        format.html { redirect_to(@vmt, :notice => 'Vmt was successfully created.') }
        format.xml  { render :xml => @vmt, :status => :created, :location => @vmt }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @vmt.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /vmts/1
  # PUT /vmts/1.xml
  def update
    @vmt = Vmt.find(params[:id])

    respond_to do |format|
      if @vmt.update_attributes(params[:vmt])
        format.html { redirect_to(@vmt, :notice => 'Vmt was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @vmt.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /vmts/1
  # DELETE /vmts/1.xml
  def destroy
    @vmt = Vmt.find(params[:id])
    @vmt.destroy

    respond_to do |format|
      format.html { redirect_to(vmts_url) }
      format.xml  { head :ok }
    end
  end
end

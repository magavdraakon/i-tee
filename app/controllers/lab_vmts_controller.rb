class LabVmtsController < ApplicationController
  # GET /lab_vmts
  # GET /lab_vmts.xml
  before_filter :authorise_as_admin
  def index
    @lab_vmts = LabVmt.find(:all, :order=>params[:sort_by])
    @lab_vmt = LabVmt.new
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @lab_vmts }
    end
  end
  

  # GET /lab_vmts/new
  # GET /lab_vmts/new.xml
  def new
    @lab_vmt = LabVmt.new
    @labs= Lab.all
    @vmts= Vmt.all
    if params[:lab]!=nil
      @lab = Lab.find(params[:lab])
    end
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @lab_vmt }
    end
  end

  # GET /lab_vmts/1/edit
  def edit
    @lab_vmt = LabVmt.find(params[:id])
    @lab=@lab_vmt.lab
    @labs= Lab.all
    @vmts= Vmt.all
  end

  # POST /lab_vmts
  # POST /lab_vmts.xml
  def create
    @lab_vmt = LabVmt.new(params[:lab_vmt])

    respond_to do |format|
      if @lab_vmt.save
        format.html { redirect_to(lab_vmts_url, :notice => 'Lab vmt was successfully created.') }
        format.xml  { render :xml => @lab_vmt, :status => :created, :location => @lab_vmt }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @lab_vmt.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /lab_vmts/1
  # PUT /lab_vmts/1.xml
  def update
    @lab_vmt = LabVmt.find(params[:id])

    respond_to do |format|
      if @lab_vmt.update_attributes(params[:lab_vmt])
        format.html { redirect_to(lab_vmts_url, :notice => 'Lab vmt was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @lab_vmt.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /lab_vmts/1
  # DELETE /lab_vmts/1.xml
  def destroy
    @lab_vmt = LabVmt.find(params[:id])
    @lab_vmt.destroy

    respond_to do |format|
      format.html { redirect_to(lab_vmts_url) }
      format.xml  { head :ok }
    end
  end
end

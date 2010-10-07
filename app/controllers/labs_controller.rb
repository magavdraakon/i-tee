class LabsController < ApplicationController
  layout 'main'

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
    @lab = Lab.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @lab }
    end
  end

  # GET /labs/new
  # GET /labs/new.xml
  def new
    @lab = Lab.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @lab }
    end
  end

  # GET /labs/1/edit
  def edit
    @lab = Lab.find(params[:id])
  end

  # POST /labs
  # POST /labs.xml
  def create
    @lab = Lab.new(params[:lab])

    respond_to do |format|
      if @lab.save
        format.html { redirect_to(@lab, :notice => 'Lab was successfully created.') }
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
end

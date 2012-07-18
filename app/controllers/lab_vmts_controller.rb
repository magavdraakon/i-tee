class LabVmtsController < ApplicationController
  #restricted to admins
  before_filter :authorise_as_admin
  #redirect to index view when trying to see unexisting things
  before_filter :save_from_nil, :only=>[:edit]
  before_filter :admin_tab
  def save_from_nil
    @lab_vmt = LabVmt.find_by_id(params[:id])
    if @lab_vmt==nil 
      redirect_to(lab_vmts_path,:notice=>"invalid id.")
    end
  end
  
  # GET /lab_vmts
  # GET /lab_vmts.xml
  #index and new view are merged, but there is also a separate view for new 
  def index
    @lab_vmts = LabVmt.find(:all, :order=>params[:sort_by])
    @lab_vmts = @lab_vmts.paginate(:page=>params[:page], :per_page=>10)
    @lab_vmt = LabVmt.new
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @lab_vmts }
    end
  end
  


  # GET /lab_vmts/1/edit
  def edit
   # @lab_vmt = LabVmt.find(params[:id])
    @lab=@lab_vmt.lab
    
  end

  # POST /lab_vmts
  # POST /lab_vmts.xml
  def create
    @lab_vmt = LabVmt.new(params[:lab_vmt])
    
    if params[:from]=="labs/show"
      # if we go to the lab, we need lab info
      @lab = Lab.find(params[:lab_vmt][:lab_id])
      redirect_path=lab_path(@lab.id)
    else
      # if we go to the list, we need the list items.
      @lab_vmts = LabVmt.find(:all, :order=>params[:sort_by])
      @lab_vmts = @lab_vmts.paginate(:page=>params[:page], :per_page=>10)
      redirect_path=lab_vmts_path
    end
    
    respond_to do |format|
      if @lab_vmt.save
        format.html { redirect_to(redirect_path, :notice => 'Lab vmt was successfully created.') }
        format.xml  { render :xml => @lab_vmt, :status => :created, :location => @lab_vmt }
      else
        format.html { render params[:from] }
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
      format.html { redirect_to(:back) }
      format.xml  { head :ok }
    end
  end
end

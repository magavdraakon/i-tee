class LabVmtsController < ApplicationController
  #restricted to admins
  before_action :authorise_as_admin
  #redirect to index view when trying to see unexisting things
  before_action :set_lab_vmt, :only=>[:edit, :show, :update, :destroy]
  before_action :admin_tab
   
  # GET /lab_vmts
  # GET /lab_vmts.xml
  #index and new view are merged, but there is also a separate view for new 
  def index
    set_order_by
    @lab_vmts = LabVmt.order(@order)
    @lab_vmts = @lab_vmts.paginate(:page=>params[:page], :per_page=>@per_page)
    @lab_vmt = LabVmt.new
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @lab_vmts }
    end
  end
  
  # GET /lab_vmts/1/edit
  def edit
    @lab=@lab_vmt.lab
  end

  # POST /lab_vmts
  # POST /lab_vmts.xml
  def create
    @lab_vmt = LabVmt.new(lab_vmt_params)
    set_order_by
    if params[:from]=='labs/show'
      # if we go to the lab, we need lab info
      @lab = Lab.find(params[:lab_vmt][:lab_id])
      redirect_path = lab_path(@lab.id)
    else
      # if we go to the list, we need the list items.
      @lab_vmts = LabVmt.order(@order)
      @lab_vmts = @lab_vmts.paginate(:page=>params[:page], :per_page=>@per_page)
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
    respond_to do |format|
      if @lab_vmt.update_attributes(lab_vmt_params)
        format.html { redirect_to(lab_vmts_url, :notice => 'Lab vmt was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => 'edit' }
        format.xml  { render :xml => @lab_vmt.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /lab_vmts/1
  # DELETE /lab_vmts/1.xml
  def destroy
    @lab_vmt.destroy
    respond_to do |format|
      format.html { redirect_back fallback_location: lab_vmts_path }
      format.xml  { head :ok }
    end
  end

  private # -------------------------------------------------------
  def set_lab_vmt
    @lab_vmt = LabVmt.where(id: params[:id]).first
    unless @lab_vmt
      redirect_to(lab_vmts_path,:notice=>'invalid id.')
    end
  end

  def lab_vmt_params
    params.require(:lab_vmt).permit(:id, :name, :lab_id, :vmt_id, :allow_remote, :allow_clipboard, :nickname, :position, :g_type, :primary, :allow_restart, :expose_uuid, :enable_rdp)
  end
end

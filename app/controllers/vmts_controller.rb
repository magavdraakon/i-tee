class VmtsController < ApplicationController
  #restricted to admins 
  before_action :authorise_as_admin
  #redirect to index view when trying to see unexisting things
  before_action :set_vmt, :only=>[:show, :edit, :update, :destroy]

  before_action :admin_tab  
  # GET /vmts
  # GET /vmts.xml
  def index
    set_order_by
    @vmts = Vmt.order(@order).paginate(:page=>params[:page], :per_page=>@per_page)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @vmts }
    end
  end

  # GET /vmts/1
  # GET /vmts/1.xml
  def show
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
  end

  # POST /vmts
  # POST /vmts.xml
  def create
    @vmt = Vmt.new(vmt_params)

    respond_to do |format|
      if @vmt.save
        format.html { redirect_to(@vmt, :notice => 'Vmt was successfully created.') }
        format.xml  { render :xml => @vmt, :status => :created, :location => @vmt }
      else
        format.html { render :action => 'new' }
        format.xml  { render :xml => @vmt.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /vmts/1
  # PUT /vmts/1.xml
  def update
    respond_to do |format|
      if @vmt.update_attributes(vmt_params)
        format.html { redirect_to(@vmt, :notice => 'Vmt was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => 'edit' }
        format.xml  { render :xml => @vmt.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /vmts/1
  # DELETE /vmts/1.xml
  def destroy
    @vmt.destroy
    respond_to do |format|
      format.html { redirect_to(vmts_url) }
      format.xml  { head :ok }
    end
  end  

private # ------------------------------------------------------
  def set_vmt
    @vmt = Vmt.where(id: params[:id]).first
    unless @vmt 
      redirect_to(vmts_path,:notice=>'invalid id.')
    end
  end
  def vmt_params
     params.require(:vmt).permit(:id, :image, :username)
  end
  
end

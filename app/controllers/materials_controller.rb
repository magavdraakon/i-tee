class MaterialsController < ApplicationController
  
  #restricted to admins, users can only view the material
  before_filter :authorise_as_admin, :except => [:show]
  #redirect to index view when trying to see unexisting things
  before_filter :set_material, :only=>[:show, :edit, :update, :destroy]
  before_filter :admin_tab, :except=>[:show]
  
  # GET /materials
  # GET /materials.xml
  def index
    set_order_by
    @materials = Material.order(@order).paginate(:page=>params[:page], :per_page=>@per_page)
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @materials }
    end
  end

  # GET /materials/1
  # GET /materials/1.xml
  def show
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @material }
    end
  end

  # GET /materials/new
  # GET /materials/new.xml
  def new
    @material = Material.new
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @material }
    end
  end

  # GET /materials/1/edit
  def edit
  end

  # POST /materials
  # POST /materials.xml
  def create
    @material = Material.new(material_params)
    respond_to do |format|
      if @material.save
        format.html { redirect_to(@material, :notice => 'Material was successfully created.') }
        format.xml  { render :xml => @material, :status => :created, :location => @material }
      else
        format.html { render :action => 'new' }
        format.xml  { render :xml => @material.errors, :status => :unprocessable_entity }
      end
    end
  end
  
  # PUT /materials/1
  # PUT /materials/1.xml
  def update
    respond_to do |format|
      if @material.update_attributes(material_params)
        format.html { redirect_to(@material, :notice => 'Material was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => 'edit' }
        format.xml  { render :xml => @material.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /materials/1
  # DELETE /materials/1.xml
  def destroy
    @material.destroy
    respond_to do |format|
      format.html { redirect_to(materials_url) }
      format.xml  { head :ok }
    end
  end


  private # -------------------------------------------------------
  def set_material
    @material = Material.where(id: params[:id]).first
    unless @material
      redirect_to(materials_path,:notice=>'invalid id.')
    end
  end

  def material_params
    params.require(:material).permit(:id, :name, :source)
  end
end

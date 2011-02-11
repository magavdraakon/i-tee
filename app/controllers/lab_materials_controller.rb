class LabMaterialsController < ApplicationController
  # GET /lab_materials
  # GET /lab_materials.xml
   before_filter :authorise_as_admin

  
  def index
    @lab_materials = LabMaterial.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @lab_materials }
    end
  end

  # GET /lab_materials/1
  # GET /lab_materials/1.xml
  def show
    @lab_material = LabMaterial.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @lab_material }
    end
  end
  
  # GET /lab_materials/new
  # GET /lab_materials/new.xml
  def new
    @lab_material = LabMaterial.new
    @labs= Lab.all
    lab_materials=[]
    if params[:lab]!=nil
      @lab = Lab.find(params[:lab])
      @lab.lab_materials.each do |m|
        lab_materials<<m.material
      end  
    end
    @materials= Material.all-lab_materials
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @lab_material }
    end
  end

  # GET /lab_materials/1/edit
  def edit
    @lab_material = LabMaterial.find(params[:id])
    @lab = @lab_material.lab
    @labs= Lab.all
    @materials= Material.all
  end

  # POST /lab_materials
  # POST /lab_materials.xml
  def create
    @lab_material = LabMaterial.new(params[:lab_material])
    @lab=@lab_material.lab
    respond_to do |format|
      if @lab_material.save
        format.html {  redirect_to(:controller=>'labs', :action=>'show', :id=>@lab) }
       # format.html { redirect_to(@lab_material, :notice => 'Lab material was successfully created.') }
        format.xml  { render :xml => @lab_material, :status => :created, :location => @lab_material }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @lab_material.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /lab_materials/1
  # PUT /lab_materials/1.xml
  def update
    @lab_material = LabMaterial.find(params[:id])

    respond_to do |format|
      if @lab_material.update_attributes(params[:lab_material])
        format.html { redirect_to(@lab_material, :notice => 'Lab material was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @lab_material.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /lab_materials/1
  # DELETE /lab_materials/1.xml
  def destroy
    @lab_material = LabMaterial.find(params[:id])
    @lab=@lab_material.lab
    @lab_material.destroy
   
    if params[:location] == "labs"
     respond_to do |format|
      format.html { redirect_to(:controller=>'labs', :action=>'show', :id=>@lab) }
      format.xml  { head :ok }
    end
  else
    
    respond_to do |format|
      format.html { redirect_to(:controller=>'lab_materials', :action=>'index') }
      format.xml  { head :ok }
    end
  end
end
end

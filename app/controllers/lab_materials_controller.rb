class LabMaterialsController < ApplicationController
  
  #restricted to admins
   before_filter :authorise_as_admin
  
    #redirect to index view when trying to see unexisting things
  before_filter :save_from_nil, :only=>[:show, :edit]
  
  def save_from_nil
    @lab_material = LabMaterial.find_by_id(params[:id])
    if @lab_material==nil 
      redirect_to(lab_materials_path,:notice=>"invalid id.")
    end
  end


  # GET /lab_materials
  # GET /lab_materials.xml  
  def index
    @lab_materials = LabMaterial.find(:all, :order=>params[:sort_by])
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @lab_materials }
    end
  end

  # GET /lab_materials/1
  # GET /lab_materials/1.xml
  def show
    #@lab_material = LabMaterial.find(params[:id])

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
    
    #find_by_id returns nil if there is no such lab_material
    @lab = Lab.find_by_id(params[:lab])
    # if the lab is preset, add all the materials already bound with it in an array
    if @lab!=nil
      @lab.lab_materials.each do |m|
        lab_materials<<m.material
      end
    end
    #take away the materials that are already bound with the lab
    @materials= Material.all-lab_materials
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @lab_material }
    end
  end

  # GET /lab_materials/1/edit
  def edit
    #@lab_material = LabMaterial.find(params[:id])
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
   
    respond_to do |format|
      format.html { redirect_to(:back) }
      format.xml  { head :ok }
    end
end
end

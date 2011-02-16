class LabUsersController < ApplicationController
  # GET /lab_users
  # GET /lab_users.xml
  before_filter :authorise_as_admin
  def index
    @lab_users = LabUser.find(:all, :order=>params[:sort_by])
    @lab_user = LabUser.new
    
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @lab_users }
    end
  end

  

  # GET /lab_users/1/edit
  def edit
    @lab_user = LabUser.find(params[:id])
  end

  # POST /lab_users
  # POST /lab_users.xml
  def create
    @lab_user = LabUser.new(params[:lab_user])

    respond_to do |format|
      if @lab_user.save
        format.html { redirect_to(lab_users_url, :notice => 'Lab user was successfully created.') }
        format.xml  { render :xml => @lab_user, :status => :created, :location => @lab_user }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @lab_user.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /lab_users/1
  # PUT /lab_users/1.xml
  def update
    @lab_user = LabUser.find(params[:id])

    respond_to do |format|
      if @lab_user.update_attributes(params[:lab_user])
        format.html { redirect_to(lab_users_url, :notice => 'Lab user was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @lab_user.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /lab_users/1
  # DELETE /lab_users/1.xml
  def destroy
    @lab_user = LabUser.find(params[:id])
    @lab_user.destroy

    respond_to do |format|
      format.html { redirect_to(lab_users_url) }
      format.xml  { head :ok }
    end
  end
end

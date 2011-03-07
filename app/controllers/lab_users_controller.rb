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

     if params[:lab_user][:page]=='bulk_add' then
      all_users=User.all
      checked_users=get_users_from(params[:users])
      removed_users=all_users-checked_users
      lab=params[:lab_user][:lab_id]
      
      checked_users.each do |c|
        l=LabUser.new
        l.lab_id=lab
        l.user_id=c.id
        if LabUser.find(:first, :conditions=>["lab_id=? and user_id=?", lab, c.id])==nil then
          l.save
        end
      end
      removed_users.each do |d|
        l=LabUser.find(:first, :conditions=>["lab_id=? and user_id=?", lab, d.id])
        l.delete if l!=nil
      end
      redirect_to(lab_users_url, :notice => 'successful update.')
    else
      
       @lab_user = LabUser.new(params[:lab_user])
    respond_to do |format|
      if @lab_user.save
        
        format.html { redirect_to(lab_users_url, :notice => 'successful update.') }
        format.xml  { render :xml => @lab_user, :status => :created, :location => @lab_user }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @lab_user.errors, :status => :unprocessable_entity }
      end
    end
  end
  end

  # PUT /lab_users/1
  # PUT /lab_users/1.xml
  def update
    @lab_user = LabUser.find(params[:id])
    
    respond_to do |format|
      if @lab_user.update_attributes(params[:lab_user])
        format.html { redirect_to(lab_users_url, :notice => 'successful update.') }
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
    #when removing someone from a lab, you need to thow their machines away too
    @lab_user.lab.lab_vmts.each do |template|
      vm=Vm.find(:first, :conditions=>["lab_vmt_id=? and user_id=?", template.id, @lab_user.user.id ])
      vm.destroy if vm!=nil
    end
    
    @lab_user.destroy

    respond_to do |format|
      format.html { redirect_to(lab_users_url) }
      format.xml  { head :ok }
    end
  end
  
  def add_users
    @lab_users = LabUser.all
    @lab_user = LabUser.new
    if params[:id]==nil then
      @lab=Lab.first
    else
      @lab=Lab.find(params[:id])
    end
    @users_in=[]
    @lab.lab_users.each do |u|
      @users_in<<u.user
    end
  end
  private #-----------------------------------------------
  def get_users_from(u_list)
    u_list=[] if u_list.blank?
    return u_list.collect{|u| User.find_by_id(u.to_i)}.compact
  end
end

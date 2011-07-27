class LabUsersController < ApplicationController
  #restricted to admins 
  before_filter :authorise_as_admin
  #redirect to index view when trying to see unexisting things
  before_filter :save_from_nil, :only=>[:edit]
  before_filter :admin_tab
  def save_from_nil
    @lab_user = LabUser.find_by_id(params[:id])
    if @lab_user==nil 
      redirect_to(lab_users_path,:notice=>"invalid id.")
    end
  end

  
  # GET /lab_users
  # GET /lab_users.xml
  #index and new view are merged
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
    #@lab_user = LabUser.find(params[:id])
  end

  # POST /lab_users
  # POST /lab_users.xml
  def create
    @lab_users = LabUser.find(:all, :order=>params[:sort_by])
    # logic for when adding/removing multiple users at once to a specific lab
    if params[:lab_user][:page]=='bulk_add' then
      all_users=User.all
      checked_users=get_users_from(params[:users])
      removed_users=all_users-checked_users
      lab=params[:lab_user][:lab_id]
      
      checked_users.each do |c|
        l=LabUser.new
        l.lab_id=lab
        l.user_id=c.id
        #if there is no db row with the se parameters then create one
        if LabUser.find(:first, :conditions=>["lab_id=? and user_id=?", lab, c.id])==nil then
          l.save
        end
      end
      removed_users.each do |d|
        #look for the unchecked users and remove them from db if they were there
        l=LabUser.find(:first, :conditions=>["lab_id=? and user_id=?", lab, d.id])
        l.delete if l!=nil
      end
      redirect_to(lab_users_path, :notice => 'successful update.')
      elese
      #adding a single user to a lab
      @lab_user = LabUser.new(params[:lab_user])
      respond_to do |format|
        if @lab_user.save
        format.html { redirect_to(lab_users_path, :notice => 'successful update.') }
        format.xml  { render :xml => @lab_user, :status => :created, :location => @lab_user }
      else
        format.html { render :action => "index" }
        format.xml  { render :xml => @lab_user.errors, :status => :unprocessable_entity}
      end #end if
    end #end respond_to
  end #end else
end

  # PUT /lab_users/1
  # PUT /lab_users/1.xml
  def update
    @lab_user = LabUser.find(params[:id])
    
    respond_to do |format|
      if @lab_user.update_attributes(params[:lab_user])
        format.html { redirect_to(lab_users_path, :notice => 'successful update.') }
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
      format.html { redirect_to(lab_users_path) }
      format.xml  { head :ok }
    end
  end
  
  #view for adding multiple users to a lab
  def add_users
    @lab_users = LabUser.all
    @lab_user = LabUser.new 
    #if no lab is set, take the first
    @lab=Lab.find_by_id(params[:id])
    if @lab==nil then
      @lab=Lab.first
      redirect_to(add_users_path) if params[:id]!=nil
    end
    #users already in the particular lab
    @users_in=[]
    @lab.lab_users.each do |u|
      @users_in<<u.user
    end
  end
  private #-----------------------------------------------
  # return a array of users based on the input (list of checked checkboxes)
  def get_users_from(u_list)
    u_list=[] if u_list.blank?
    return u_list.collect{|u| User.find_by_id(u.to_i)}.compact
  end
end

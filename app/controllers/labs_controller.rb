class LabsController < ApplicationController  
  #users can see courses, running labs and end their OWN lab
  before_action :authorise_as_admin, :except => [:start_lab, :end_lab, :restart_lab, :lab_view]

  #redirect to index view when trying to see unexisting things
  before_action :set_lab, :only=>[:show, :edit, :update, :destroy]
  # set the menu tab to show the user
  before_action :course_tab, :only=>[:lab_view]
  before_action :admin_tab, :except=>[:lab_view]
  
  # GET /labs
  # GET /labs.xml
  def index
    set_order_by
    @labs = Lab.order(@order).paginate(:page=>params[:page], :per_page=>@per_page)
    if params[:conditions]
      labs = Lab.where(params[:conditions].as_json)
    else
      labs = Lab.all
    end
    respond_to do |format|
      format.html # index.html.erb
      format.json  { render :json => labs }
    end
  end

  # GET /labs/1
  # GET /labs/1.xml
  def show
    #@lab = Lab.find(params[:id])
    @lab_vmt=LabVmt.new
    @lab_badge=LabBadge.new
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @lab }
    end
  end

  # GET /labs/new
  # GET /labs/new.xml
  def new
    @lab = Lab.new
    @lab.lab_vmts.build.lab_vmt_networks.build
    @all_users=false
    @user_count=0
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @lab }
    end
  end

  # GET /labs/1/edit
  def edit
    @lab.lab_vmts.each do |v|
      v.lab_vmt_networks.build
    end
    @lab.lab_vmts.build.lab_vmt_networks.build
    
    #@lab = Lab.find(params[:id])
    @all_users=false
    @user_count =0
    @user_count = @lab.lab_users.count  
    @all_users=true if User.all.count==@user_count
  end
  
  # POST /labs
  # POST /labs.xml
  def create
    @lab = Lab.new(lab_params)
    @all_users=false
    @user_count=0
    respond_to do |format|
      if @lab.save
                
        @lab.add_all_users  if params[:add] && params[:add].to_s==1.to_s
        @lab.remove_all_users if params[:remove] && params[:remove].to_s==1.to_s 
        
        format.html { redirect_to(@lab, :notice => "Lab was successfully created. #{params[:add]}") }
        format.json  { render :json => { :success => true, :lab=> @lab.as_json} }
      else
        format.html { render :action => 'new' }
        format.json  { render :json => {:success=>false, :errors=>@lab.errors}, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /labs/1
  # PUT /labs/1.xml
  def update
    respond_to do |format|
      @all_users=false
      @user_count =0
      @user_count = @lab.lab_users.count  
      @all_users=true if User.all.count==@user_count
      if @lab.update_attributes(lab_params)
       
        @lab.add_all_users  if params[:add].to_s==1.to_s    
        @lab.remove_all_users if params[:remove].to_s==1.to_s 
          
        format.html { redirect_to(@lab, :notice => 'Lab was successfully updated.') }
        format.json  { render :json => {:success=>true, :lab=> @lab.as_json} }
      else
        format.html { render :action => 'edit' }
        format.json  { render :json => {:success=>false, :errors=>@lab.errors}, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /labs/1
  # DELETE /labs/1.xml
  def destroy
    respond_to do |format|
        if @lab
          @lab.destroy

          format.html { redirect_to(labs_url, :notice=>'Lab deleted') }
          format.json  { render :json => {:success=>true, :message=>'Lab deleted'} }
        else
          format.html { redirect_to(labs_url, :notice=>"Can't find lab") }
          format.json  { render :json => {:success=>false, :message=>"Can't find lab"}}
        end
    end
  end

# search for labs to end all of their attempts (lab_users) etc.
 def search

 end

 # newer lab view focused on displaying lab attempts and allowing multiple attempts per lab (since 2018)
  def lab_view
    begin
      if params[:id].blank?  # by default the page belongs to the current user
        @lab_user = current_user.lab_users.first
      else # but the attempt might belong to someone else
        @lab_user = LabUser.where(id: params[:id]).first 
      end
      raise "Lab attempt not found" unless @lab_user
      raise "permission denied" unless @admin || @lab_user.user == current_user # unless admin or owner
      @user = @lab_user.user
      @lab_users = @user.lab_users.includes(:lab).order(end: :asc, start: :desc)
      
    rescue Exception => e
      logger.error e
      flash[:alert] =  e.message || "Problem viewing Lab Attempts"
      redirect_to root_path
    end
  end
  
  # API-only endpoint for starting a lab attempt
  def start_lab_by_id
    respond_to do |format|
      begin
        raise "unsupported request format. Use .json" unless request.format == :json
        raise "Restricted Access" unless @admin 
        raise "Lab attempt not specified" if params[:labuser_id].blank?
        @labuser = LabUser.where(id: params[:labuser_id]).first
        raise  "Can't find lab attempt" unless @labuser
        # generating vm info if needed
        result = @labuser.start_lab
        format.json {
          render :json=>{ :success => result[:success] , :message=> result[:message], :lab_user => @labuser.id, :start_time => @labuser.start }
        }     
      rescue Exception => e
        logger.error "LAB START FAILED: "
        logger.error e
        message = e.message || "Problem starting Lab Attempts"
        format.json { render :json=> {:success => false , :message=> message }}
      end
    end
  end

  # method for starting a lab, creates virtual machine db rows and sets the start time for the lab
  def start_lab
    @fallback_location = lab_view_path
    respond_to do |format|
      begin
        @lab_user = LabUser.where(id: params[:id]).first 
        raise "Lab attempt not found" unless @lab_user 
        raise "permission denied" unless @admin || @lab_user.user == current_user # unless admin or owner
        logger.debug "Starting '#{@lab_user.user.username}' lab '#{@lab_user.lab.name}' as admin" if @admin && @lab_user.user != current_user # admin in someone else's lab
        @fallback_location = lab_view_path+"/"+@lab_user.id.to_s
        result = @lab_user.start_lab
        format.html { 
          flash[:notice] = result[:message]
          redirect_back fallback_location: @fallback_location
        }
        format.json {render :json=>{ :success => result[:success] , :message=> result[:message], :lab_user => @lab_user.id, :start_time => @lab_user.start }}
      rescue Exception => e
        logger.error e
        message = e.message || "Problem starting Lab Attempts"
        format.html { 
          flash[:alert] =  message
          redirect_back fallback_location: @fallback_location
        }
        format.json { render :json=> {:success => false , :message=> message }}
      end
    end
  end
  
  # API-only endpoint for ending lab attempts
  def end_lab_by_id
    respond_to do |format|
      begin
        raise "unsupported request format. Use .json" unless request.format == :json
        raise "Restricted Access" unless @admin 
        raise "Lab attempt not specified" if params[:labuser_id].blank?
        @labuser = LabUser.where(id: params[:labuser_id]).first
        raise  "Can't find lab attempt" unless @labuser
        result = @labuser.end_lab
        logger.debug "mission #{@labuser.id} end result: #{result.as_json}"
        format.json {
          render :json=>{ :success => result[:success] , :message=> result[:message], :lab_user => @labuser.id , :end_time => @labuser.end}
        }    
      rescue Exception => e
        logger.error "LAB END FAILED: "
        logger.error e
        message = e.message || "Problem ending Lab Attempts"
        format.json { render :json=> {:success => false , :message=> message }}
      end
    end
  end

  # API-only method to end lab by username and lab id
  def end_lab_by_values
    respond_to do |format|
      begin
        raise "unsupported request format. Use .json" unless request.format == :json
        raise "Restricted access" unless @admin
        user = User.where(username: params[:user_name]).first
        raise "User not found" unless user
        @labuser = LabUser.where(lab_id: params[:lab_id], user_id: user.id ).last
        raise "Lab attempt not found" unless @labuser
        result = @labuser.end_lab
        logger.debug "mission #{@labuser.id} end result: #{result.as_json}"
        format.json {render :json=>{ :success => result[:success] , :message=> result[:message], :lab_user => @labuser.id , :end_time => @labuser.end}}
      rescue Exception => e
        logger.error "LAB END BY VALUES FAILED: "
        logger.error e
        message = e.message || "Problem ending Lab Attempts"
        format.json { render :json=> {:success => false , :message=> message }}
      end
    end
  end

  #method for ending a lab, deletes virtual machine db rows and sets the end date for the lab
  def end_lab
    @fallback_location = lab_view_path
    respond_to do |format|
      begin
        @lab_user = LabUser.where(id: params[:id]).first 
        raise "Lab attempt not found" unless @lab_user 
        raise "permission denied" unless @admin || @lab_user.user == current_user # unless admin or owner
        logger.debug "ending '#{@lab_user.user.username}' lab '#{@lab_user.lab.name}' as admin" if @admin && @lab_user.user != current_user # admin in someone else's lab
        @fallback_location = lab_view_path+"/"+@lab_user.id.to_s
        result = @lab_user.end_lab
        logger.debug "mission #{@lab_user.id} end result: #{result.as_json}"
        # back to the view the link was in
        format.html {
          flash[:notice] = result[:message]
          redirect_back fallback_location: @fallback_location
        }
        format.json {render :json=>{ :success => result[:success] , :message=> result[:message], :lab_user => @lab_user.id , :end_time => @lab_user.end}}
      rescue Exception => e
        logger.error e
        message = e.message || "Problem ending Lab Attempts"
        format.html { 
          flash[:alert] =  message
          redirect_back fallback_location: @fallback_location
        }
        format.json { render :json=> {:success => false , :message=> message }}
      end
    end
  end
  
  # API-only endpoint for restarting a lab attempt.
  def restart_lab_by_id
    respond_to do |format|
      begin
        raise "unsupported request format. Use .json" unless request.format == :json
        raise "Restricted Access" unless @admin 
        raise "Lab attempt not specified" if params[:labuser_id].blank?
        @labuser = LabUser.where(id: params[:labuser_id]).first
        raise  "Can't find lab attempt" unless @labuser
        result = @labuser.restart_lab
        format.json {render :json=>{ :success => result[:success] , :message=> result[:message], :lab_user => @labuser.id, :start_time => @labuser.start }}   
      rescue Exception => e
        logger.error "LAB RESTART FAILED: "
        logger.error e
        message = e.message || "Problem restarting Lab Attempts"
        format.json { render :json=> {:success => false , :message=> message }}
      end
    end
  end

  # Restarting a lab means deleting virtual machines and removing start/end times
  def restart_lab
    @fallback_location = lab_view_path
    respond_to do |format|
      begin
        @lab_user = LabUser.where(id: params[:id]).first 
        raise "Lab attempt not found" unless @lab_user 
        raise "permission denied" unless @admin || @lab_user.user == current_user # unless admin or owner
        logger.debug "Restarting '#{@lab_user.user.username}' lab '#{@lab_user.lab.name}' as admin\n" if @admin && @lab_user.user != current_user # admin in someone else's lab
        @fallback_location = lab_view_path+"/"+@lab_user.id.to_s
        result = @lab_user.restart_lab
        # redirect back to the view the link was in
        format.html {
          flash[:notice] = result[:message]
          redirect_back fallback_location: @fallback_location
        }
        format.json {render :json=>{ :success => result[:success] , :message=> result[:message], :lab_user => @lab_user.id, :start_time => @lab_user.start }}
      rescue Exception => e
        logger.error e
        message = e.message || "Problem ending Lab Attempts"
        format.html { 
          flash[:alert] =  message
          redirect_back fallback_location: @fallback_location
        }
        format.json { render :json=> {:success => false , :message=> message }}
      end
    end
  end
  

  private #----------------------------------------------------------------------------------
   def get_user_labs(user)
    @labs=[] #only let the users pick from labs assigned to them
    @started=[]
    @complete=[]
    @not_started=[]
    #categorize the labs, order: running, not started, ended
    labusers = LabUser.order(end: :desc, start: :desc).where(user_id: user.id).map{|u|u}
    lab_ids = labusers.map {|lu| lu[:lab_id]}.flatten.uniq
    labs = Lab.where(id: lab_ids).map{|l|l}
    labusers.each do |u|
      ll = labs.select {|l| l.id == u.lab_id}.first 
      @labs << ll       
      @started << ll  if u.start && !u.end 
      @complete << ll  if u.start && u.end 
    end 
    @not_started=@labs-@started-@complete
  end
  
  def get_user
    @user=current_user # by default get the current user
    if  @admin  #  admins can use this to view users labs
      if params[:username]  # if there is a username in the url
        @user = User.where(username: params[:username]).first
      end
      if params[:user_id]  # if there is a user_id in the url
        @user = User.where(id: params[:user_id]).first
      end
    end
  end


  def set_lab
    @lab = Lab.where(id: params[:id]).first
    unless @lab
      redirect_to(labs_path,:notice=>'invalid id.')
    end
  end

  def lab_params
    params.require(:lab).permit(:id, :name, :description, :config, :short_description, :host_id, :restartable, :endable, :startAll, :vms_by_one, :poll_freq, :end_timeout, :power_timeout, :lab_hash, :lab_token, :assistant_id, :ping_low, :ping_mid, :ping_high, 
      lab_vmts_attributes: [:id, :name, :lab_id, :vmt_id, :allow_remote, :nickname, :position, :g_type, :primary, :allow_restart, :expose_uuid, :enable_rdp, :_destroy, lab_vmt_networks_attributes: [:id, :network_id, :slot, :lab_vmt_id, :promiscuous, :reinit_mac,:ip, :_destroy]
        ]
      )
  end
end

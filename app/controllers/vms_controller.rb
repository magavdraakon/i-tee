# encoding: utf-8
class VmsController < ApplicationController
  before_action :authorise_as_admin, :only => [:new, :edit, :get_state, :get_rdp, :start_all_by_id, :stop_all_by_id, :labuser_vms ]
  
  #before_action :authorise_as_admin, :except => [:show, :index, :init_vm, :stop_vm, :pause_vm, :resume_vm, :start_vm, :start_all]
  #redirect to index view when trying to see unexisting things
  before_action :set_vm, :only=>[:show, :edit, :update, :destroy, :start_vm, :stop_vm, :pause_vm, :resume_vm, :get_state, :get_rdp, :rdp_reset,:open_guacamole, :send_text, :send_keys, :guacamole_view, :readonly_view ]
  before_action :auth_as_owner, :only=>[:show, :start_vm, :stop_vm, :pause_vm, :resume_vm, :get_state, :get_rdp, :rdp_reset ,:open_guacamole, :send_text, :send_keys, :guacamole_view, :readonly_view]       
  
  before_action :admin_tab, :except=>[:show,:index, :vms_by_lab, :vms_by_state]
  before_action :vm_tab, :only=>[:show,:index, :vms_by_lab, :vms_by_state]

  skip_before_action :authenticate_user!, :only => [:network]
  
  def vms_by_lab
    @b_by='lab'
    sql=[]
    order = order_vms
    if !params[:admin].blank? && @admin # admin user
      @lab = Lab.find(params[:id]) if params[:id]# try to get the selected lab
      @lab = Lab.first unless params[:id] # but if the parameter is not set, take the first lab
      # get the vm templates in the lab
      vmt_ids = (@lab.blank? ? [] : @lab.lab_vmts.map{|lv| lv.id }.flatten.uniq)
      # find all machines made from the templates
      sql = Vm.joins(:lab_user).where( lab_vmt_id: vmt_ids ).order(order)
      @tab='admin'
      @labs=Lab.all.uniq
    else # simple user
      # find lab via labuser
      @labusers = []
      @lab=false
      if params[:id].blank?
        labuser = current_user.lab_users.first # take the first known labuser to know wich lab to display
        @labusers = current_user.lab_users.where(lab_id: labuser.lab_id) if labuser
        @lab = labuser.lab if labuser
      else
        @labusers = current_user.lab_users.where(lab_id: params[:id]) 
        @lab = Lab.where(id: params[:id]).first
      end
      labuser_ids = @labusers.map{|lu| lu.id }.flatten.uniq
      # find all machines for all attempts in this lab
      sql = Vm.joins(:lab_user).where( lab_user_id: labuser_ids ).order(order)
      # get all user lab ids
      lab_ids = current_user.lab_users.map{|lu| lu.lab_id}.flatten.uniq 
      @labs = Lab.where(id: lab_ids)
    end
    @vms = sql.paginate( :page => params[:page], :per_page => @per_page) 
    render :action=>'index'
  end
  
  def vms_by_state
    @b_by='state'

    @state=params[:state] ? params[:state] : 'running'
    @state='stopped' if @state=='uninitialized'

    order = order_vms
  
    if params[:admin]!=nil && @admin # admin user
      @tab='admin'
      vms = Vm.joins(:lab_user).order(order)
    else # simple user
      labuser_ids = current_user.lab_users.map{|lu| lu.id }.flatten.uniq
      vms = Vm.joins(:lab_user).where( lab_user_id: labuser_ids ).order(order)
    end
    @vm=[]
    vms.each do |vm|
      @vm.push(vm) if vm.state(false, false)==@state
    end
    @vms=@vm.paginate(:page=>params[:page], :per_page=>@per_page)
    render :action=>'index'
  end
  
  # GET /vms
  # GET /vms.xml
  def index
    order = order_vms
    if params[:admin]!=nil && @admin # admin user
      sql = Vm.joins(:lab_user).order(order)
      @tab='admin'
    else  
      labuser_ids = current_user.lab_users.map{|lu| lu.id }.flatten.uniq
      sql = Vm.joins(:lab_user).where( lab_user_id: labuser_ids ).order(order)
    end
    @vms = sql.paginate( :page => params[:page], :per_page => @per_page) 
    
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @vms }
    end
  end

  # GET /vms/1
  # GET /vms/1.xml
  def show
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @vm }
    end
  end

  # GET /vms/new
  # GET /vms/new.xml
  def new
    @vm = Vm.new
    
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @vm }
    end
  end

  # GET /vms/1/edit
  def edit
  end
  
  # POST /vms
  # POST /vms.xml
  def create
    @vm = Vm.new(vm_params)
    respond_to do |format|
      if @vm.save
        format.html { redirect_to(vms_path+'?admin=1', :notice => 'Vm was successfully created.') }
        format.xml  { render :xml => @vm, :status => :created, :location => @vm }
      else
        format.html { render :action => 'new' }
        format.xml  { render :xml => @vm.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /vms/1
  # PUT /vms/1.xml
  def update
    respond_to do |format|
      if @vm.update_attributes(vm_params)
        format.html { redirect_to(vms_path+'?admin=1', :notice => 'Vm was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => 'edit' }
        format.xml  { render :xml => @vm.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /vms/1
  # DELETE /vms/1.xml
  def destroy
    @vm.destroy
    respond_to do |format|
      format.html { redirect_to(vms_path+'?admin=1') }
      format.xml  { head :ok }
    end
  end


  #get state of one machine-  API (admin) ONLY
  # before filters check if owner/admin 
  def get_state
    get_user
    respond_to do |format|  
      format.html  { redirect_to(root_path, :notice =>'Permission error') }
      format.json  { render :json => {:success=> true , :state=> @vm.state  } }
    end
  end

  # get rdp lines of one machine- API (admin) ONLY
  # before filters check if owner/admin 
  def get_rdp
    respond_to do |format|
      format.html  { redirect_to(root_path, :notice =>'Permission error') }
      format.json  { render :json => {:success=> true , :rdp=> @vm.get_all_rdp  } }
    end
  end

  # get vm info for labuser
  def labuser_vms
    respond_to do |format|
      @labuser = LabUser.where(id: params[:id]).first
      if @labuser
        result = @labuser.vms_info
        format.html {redirect_to root_path, :notice => 'Permission error'}
        format.json {
          logger.info "GETTING LABUSER VMS SUCCESS: labuser=#{@labuser.id} lab=#{@labuser.lab.id} user=#{@labuser.user.id} [#{@labuser.user.username}]"
          render :json=> { :success=> true, :vms=>result, :lab_user=> @labuser.id}
        }
      else        
        format.html { redirect_to root_path , :notice=> 'permission error' }
        format.json { 
          logger.error "GETTING LABUSER VMS FAILED: invalid labuser id labuser=#{params[:id]}"
          render :json=> {:success => false , :message=>  "Can't find mission" }
        }
      end      
    end
    rescue Timeout::Error
      respond_to do |format|        
        format.html {
          flash[:notice] = 'Permission error'
          redirect_back fallback_location: root_path
        }
        format.json {
          logger.error "GETTING LABUSER VMS FAILED: time out labuser=#{@labuser.id} lab=#{@labuser.lab.id} user=#{@labuser.user.id} [#{@labuser.user.username}]"
          render :json=> { :success=> false, :message=>'Getting all vms info took too long. try again later', :lab_user=> @labuser.id}
        }
      end
  end

  # start all vms by labuser id - API only
  def start_all_by_id
    respond_to do |format|
      @labuser = LabUser.find(params[:id])
      result = @labuser.start_all_vms
      format.html {redirect_to root_path, :notice => 'Permission error'}
      format.json {render :json=> { :success=> result[:success], :message=>result[:message], :lab_user=> @labuser.id}}
    end
    rescue Timeout::Error
      respond_to do |format|        
        format.html {
          flash[:notice] = 'Permission error'
          redirect_back fallback_location: root_path
        }
        format.json {render :json=> { :success=> false, :message=>'Starting all virtual machines failed, try starting them one by one.', :lab_user=> @labuser.id}}
      end
    rescue ActiveRecord::RecordNotFound
      respond_to do |format|
        logger.debug "Can't find labuser: "
        logger.debug params
        format.html { redirect_to root_path , :notice=> 'permission error' }
        format.json { render :json=> {:success => false , :message=>  "Can't find mission" }}
      end
  end

  #start all the machines this user has in a given lab
  def start_all
    respond_to do |format|
      @lab=Lab.find(params[:id])
      fallback_path = my_labs_path+(@lab ? "/#{@lab.id}" : '')+(@lab && params[:username] ? "/#{params[:username]}" : '')
      get_user
      if !@user
        logger.debug "Can't find user: "
        logger.debug params
        format.html { 
          flash[:notice] = "Can't find user"
          redirect_back fallback_location: fallback_path
        }
        format.json { render :json=> {:success => false , :message=>  "Can't find user" }}
      elsif !@admin && (params[:username] || params[:user_id])
        logger.debug '\n start_lab: Relocate user\n'
        # simple user should not have the username in url
        format.html { redirect_to my_labs_path+(params[:id] ? "/#{params[:id]}" : '') }
        format.json { render :json=>{:success => false , :message=> 'No permission error' }}
      else
        # ok, there is such lab, but does the user have it?  
        @labuser = LabUser.where('lab_id=? and user_id=?', @lab.id, @user.id).last
        if @labuser!=nil #user has this lab
          result = @labuser.start_all_vms
          format.html {
            flash[:notice] = result[:message].html_safe
            redirect_back fallback_location: fallback_path
          }
          format.json {render :json=> { :success=> result[:success], :message=>result[:message], :lab_user=> @labuser.id}}
        else
          # no this user does not have this lab
          format.html { redirect_to my_labs_path, :notice => 'That lab was not assigned to this user!' }
          format.json { render :json=>{:success => false, :message=> 'That lab was not assigned to this user!' }}
        end      
      end
    end
    rescue Timeout::Error
      respond_to do |format|        
        format.html {
          flash[:notice] = '<br/>Starting all virtual machines failed, try starting them one by one.'.html_safe
          redirect_back fallback_location: fallback_path
        }
        format.json {render :json=> { :success=> false, :message=>'Starting all virtual machines failed, try starting them one by one.', :lab_user=> @labuser.id}}
      end
    rescue ActiveRecord::RecordNotFound
      respond_to do |format|
        logger.debug "Can't find lab: "
        logger.debug params
        format.html { redirect_to my_labs_path , :notice=> "Can't find lab" }
        format.json { render :json=> {:success => false , :message=>  "Can't find lab" }}
      end
  end
  
  # start one machine 
  # view is restriced to logged in users, before filter finds vm and checks if owner/admin
  def start_vm
    respond_to do |format|
      logger.debug "\n start? \n "
      result = @vm.start_vm
        
      is_notice= (result[:notice] && result[:notice]!='')
      is_alert = (result[:alert] && result[:alert]!='')

      flash[:notice] = result[:notice].html_safe if is_notice
      flash[:alert] = result[:alert].html_safe if is_alert
      
      format.html  {
        redirect_back fallback_location: my_labs_path+(@vm.lab_vmt.lab ? "/#{@vm.lab_vmt.lab.id}" : '')+(@vm.lab_vmt.lab && params[:username] ? "/#{params[:username]}" : '')
      }
      format.json  { render :json => {:success=>is_notice, :message=> is_notice ? 'Machine started' : 'Machine start failed'} }
    end
  end
  
  #resume machine from pause
  # view is restriced to logged in users, before filter finds vm and checks if owner/admin
  def resume_vm
    respond_to do |format|
      logger.debug "\n resume? \n "
      result = @vm.resume_vm
      # TODO! check if really resumed
      format.html  { 
        flash[:notice] = result[:message].html_safe 
        redirect_back fallback_location: my_labs_path+(@vm.lab_vmt.lab ? "/#{@vm.lab_vmt.lab.id}" : '')+(@vm.lab_vmt.lab && params[:username] ? "/#{params[:username]}" : '')
      }
      format.json  { render :json => {:success=>result[:success], :message=> result[:message]  } }
    end
  end
  
  #pause a machine
  # view is restriced to logged in users, before filter finds vm and checks if owner/admin
  def pause_vm
    respond_to do |format|
      logger.debug "\n resume? \n "
      result = @vm.pause_vm
      # TODO! check if really paused
      format.html  {
        flash[:notice] = result[:message].html_safe 
        redirect_back fallback_location: my_labs_path+(@vm.lab_vmt.lab ? "/#{@vm.lab_vmt.lab.id}" : '')+(@vm.lab_vmt.lab && params[:username] ? "/#{params[:username]}" : '')
      }
      format.json  { render :json => {:success=>result[:success], :message=> result[:message] } }
    end
  end

  # start all vms by labuser id - API only
  def stop_all_by_id
    respond_to do |format|
      @labuser = LabUser.find(params[:id])
      result = @labuser.stop_all_vms
      format.html {redirect_to root_path, :notice => 'Permission error'}
      format.json {render :json=> { :success=> result[:success], :message=>result[:message], :lab_user=> @labuser.id}}
    end
    rescue Timeout::Error
      respond_to do |format|        
        format.html {
          flash[:notice] = 'Permission error'
          redirect_back fallback_location: root_path
        }
        format.json {render :json=> { :success=> false, :message=>'Starting all virtual machines failed, try starting them one by one.', :lab_user=> @labuser.id}}
      end
    rescue ActiveRecord::RecordNotFound
      respond_to do |format|
        logger.debug "Can't find labuser: "
        logger.debug params
        format.html { redirect_to root_path , :notice=> 'permission error' }
        format.json { render :json=> {:success => false , :message=>  "Can't find mission" }}
      end
  end

  #stop all the machines this user has in a given lab
def stop_all
  respond_to do |format|
    @lab=Lab.find(params[:id])
    fallback_path = my_labs_path+(@lab ? "/#{@lab.id}" : '')+(@lab && params[:username] ? "/#{params[:username]}" : '')
    get_user
    if !@user
      logger.debug "Can't find user: "
      logger.debug params
      format.html { 
        flash[:notice] = "Can't find user"
        redirect_back fallback_location: fallback_path
      }
      format.json { render :json=> {:success => false , :message=>  "Can't find user" }}
    elsif !@admin && (params[:username] || params[:user_id])
      logger.debug '\n start_lab: Relocate user\n'
      # simple user should not have the username in url
      format.html { redirect_to my_labs_path+(params[:id] ? "/#{params[:id]}" : '') }
      format.json { render :json=>{:success => false , :message=> 'No permission error' }}
    else
      # ok, there is such lab, but does the user have it?  
      @labuser = LabUser.where('lab_id=? and user_id=?', @lab.id, @user.id).last
      if @labuser!=nil #user has this lab
        result = @labuser.stop_all_vms
        format.html {
          flash[:notice] = result[:message].html_safe
          redirect_back fallback_location: fallback_path
        }
        format.json {render :json=> { :success=> result[:success], :message=>result[:message], :lab_user=> @labuser.id}}
      else
        # no this user does not have this lab
        format.html { redirect_to my_labs_path, :notice => 'That lab was not assigned to this user!' }
        format.json { render :json=>{:success => false, :message=> 'That lab was not assigned to this user!' }}
      end  
    end
  end
  rescue Timeout::Error
    respond_to do |format|        
      format.html {
        flash[:notice] = '<br/>Starting all virtual machines failed, try stoppping them one by one.'.html_safe
        redirect_back fallback_location: fallback_path
      }
      format.json {render :json=> { :success=> false, :message=>'Starting all virtual machines failed, try stoppping them one by one.', :lab_user=> @labuser.id}}
    end
  rescue ActiveRecord::RecordNotFound
    respond_to do |format|
      logger.debug "Can't find lab: "
      logger.debug params
      format.html { redirect_to my_labs_path , :notice=> "Can't find lab" }
      format.json { render :json=> {:success => false , :message=>  "Can't find lab" }}
    end
end


  # Stop the machine, do not delete the vm row from the db
  # view is restriced to logged in users, before filter finds vm and checks if owner/admin
  def stop_vm
    respond_to do |format|
      logger.debug "\n resume? \n "
      result = @vm.stop_vm
      # TODO! check if really stopped
      format.html  {
        flash[:notice] = result[:message].html_safe 
        redirect_back fallback_location: my_labs_path+(@vm.lab_vmt.lab ? "/#{@vm.lab_vmt.lab.id}" : '')+(@vm.lab_vmt.lab && params[:username] ? "/#{params[:username]}" : '')
      }
      format.json  { render :json => {:success=>result[:success], :message=> result[:message] } }
    end
  end
  
  def rdp_reset
    respond_to do |format|
      logger.debug "\n reset rdp? \n "
      result = @vm.reset_rdp
      format.html  {
        flash[:notice] = result[:message] 
        redirect_back fallback_location: my_labs_path+(@vm.lab_vmt.lab ? "/#{@vm.lab_vmt.lab.id}" : '')+(@vm.lab_vmt.lab && params[:username] ? "/#{params[:username]}" : '')
      }
      format.json  { render :json => {:success=>result[:success], :message=> result[:message] } }
    end
  end

  # guacamole related method that gives needed info for a guacamole connection as json
  def open_guacamole
    # vm by id in params
    respond_to do |format|
      result = @vm.open_guacamole
      if result && result[:success]
        format.html {
          # set cookie
          cookies[:GUAC_AUTH] = {
            value: result[:token],
            #expires: 1.hour.from_now,
            domain: result[:domain], #%w(rangeforce.com), # %w(.example.com .example.org)
            path: URI(ITee::Application::config.guacamole[:url_prefix]).path,
            #:secure,
            #:httponly
          }
          #redirect to url https://xxx.yyy.com/#/client/zzz
          redirect_to( result[:url] )
        }
        format.json  { 
          render :json => result 
        }
      else
        format.html  { redirect_to( not_found_path, :notice=> result[:message]) }
        format.json  { 
          render :json => {:success=>result[:success], :message=> result[:message] } 
        }
      end
    end
  end

  def send_text
    respond_to do |format|
      begin        
        format.html  { redirect_to( not_found_path, :notice=> "format not supported") }
        format.json  { 
          unless @vm.lab_vmt.allow_remote
            render :json => {success: false, message: "You are not allowed to send text to this machine"}
          else
            result = Virtualbox.send_text(@vm.name, params[:text])
            render :json => result 
          end
        }
      rescue Exception => e 
        format.html  { redirect_to( not_found_path, :notice=> "format not supported" ) }
        format.json  { render :json => {:success=>false, :message=> e.to_s } }
      end
    end
  end

  def send_keys
    respond_to do |format|
      begin        
        format.html  { redirect_to( not_found_path, :notice=> "format not supported") }
        format.json  { 
          unless @vm.lab_vmt.allow_remote
            render :json => {success: false, message: "You are not allowed to send keys to this machine"}
          else
            result = Virtualbox.send_keys(@vm.name, params[:text])
            render :json => result 
          end
        }
      rescue Exception => e 
        format.html  { redirect_to( not_found_path, :notice=> "format not supported" ) }
        format.json  { render :json => {:success=>false, :message=> e.to_s } }
      end
    end
  end

  def network
    # identify labuser by uuid. get machine and perform action
    # params: uuid, name, network : {slot, type, name}
    respond_to do |format|
      @labuser = LabUser.where(:uuid=>  params[:uuid]).first
      if @labuser
        vm = @labuser.vms.where(:name=> params[:name]).first
        if vm 
          params[:network] = '' if params[:network].blank?          
          result = vm.manage_network(request.method, params[:network])
          format.html { redirect_to root_path, :notice=> 'Sorry, this machine does not belong to you!' }
          format.json { render json: result }
        else
          format.html { redirect_to root_path , :notice=> 'Sorry, this machine does not belong to you!' }
          format.json { render :json=> {:success => false , :message=>  'Sorry, this machine does not belong to you!'} }
        end
      else
        format.html { redirect_to root_path , :notice=> 'Restricted access' }
        format.json { render :json=> {:success => false , :message=>  'Unable to find lab attempt'} }
      end
    end
  end

  def guacamole_view
    respond_to do |format|
      @token = @vm.rdp_token
      @ws_host = Rails.configuration.guacamole2["ws_host"]
      format.html{
        render 'guacamole_view', layout: false
      }
    end
  end

  def readonly_view
    respond_to do |format|
      @token = @vm.rdp_token(nil, true)
      @ws_host = Rails.configuration.guacamole2["ws_host"]
      @readonly = true
      format.html{
        render 'guacamole_view', layout: false
      }
    end
  end

  
private #----------------------------------------------------------------------------------
  def order_vms
    if params[:dir]=='asc'
      dir = 'ASC'
      @dir = '&dir=desc'
    else 
      dir = 'DESC'
      @dir = '&dir=asc'
    end
    # if sort by is not empty and the value is a column
    order = (!params[:sort_by].blank? && (Vm.column_names.include?(params[:sort_by]) || LabUser.column_names.include?(params[:sort_by])) ? "#{params[:sort_by]} #{dir}" : '')
    logger.debug "ORDER #{order}"
    return order
  end

   #redirect user if they are not admin or the machine owner but try to modify a machine
  def auth_as_owner
    unless current_user == @vm.lab_user.user or @admin
      respond_to do |format|
        #You don't belong here. Go away.
        format.html { redirect_to root_path , :notice=> 'Sorry, this machine does not belong to you!' }
        format.json { render :json=> {:success => false , :message=>  'Sorry, this machine does not belong to you!'} }
      end
    end
  end

  def get_user
    @user=current_user # by default get the current user
    if  @admin  #  admins can use this to view users labs
      if params[:username]  # if there is a username in the url
        @user = User.where('username = ?',params[:username]).first
      end
      if params[:user_id]  # if there is a user_id in the url
        @user = User.where('id = ?',params[:user_id]).first
      end
    end
  end

  def set_vm
    @vm = Vm.where(id: params[:id]).first
    unless @vm
      respond_to do |format|
        format.html  {redirect_to(vms_path,:notice=>'invalid id.')}
        format.json  { 
          logger.error "VM NOT FOUND: vm=#{params[:id]}"
          render :json => {:success=>false, :message=>"Can't find vm"} 
        }
      end
    end
  end

  def vm_params
     params.require(:vm).permit(:id, :name, :lab_vmt_id, :description, :password, :lab_user_id, :g_connection)
  end
end

# encoding: utf-8
class VmsController < ApplicationController
  before_filter :authorise_as_admin, :only => [:new, :edit, :get_state, :get_rdp, :start_all_by_id, :stop_all_by_id, :labuser_vms ]
  
  #before_filter :authorise_as_admin, :except => [:show, :index, :init_vm, :stop_vm, :pause_vm, :resume_vm, :start_vm, :start_all]
  #redirect to index view when trying to see unexisting things
  before_filter :save_from_nil, :only=>[:show, :edit, :start_vm, :stop_vm, :pause_vm, :resume_vm, :get_state, :get_rdp, :rdp_reset,:open_guacamole ]
  before_filter :auth_as_owner, :only=>[:show, :start_vm, :stop_vm, :pause_vm, :resume_vm, :get_state, :get_rdp, :rdp_reset ,:open_guacamole]       
  
  before_filter :admin_tab, :except=>[:show,:index, :vms_by_lab, :vms_by_state]
  before_filter :vm_tab, :only=>[:show,:index, :vms_by_lab, :vms_by_state]

  def save_from_nil
    logger.debug 'finding vm'

    @vm = Vm.find_by_id(params[:id])
    if @vm==nil 
      logger.debug "no such vm\n"
      respond_to do |format|
        format.html  {redirect_to(vms_path,:notice=>'invalid id.')}
        format.json  { render :json => {:success=>false, :message=>"Can't find vm"} }
      end
    end
  end
  
  def vms_by_lab
    @b_by='lab'
    sql=[]
    if params[:dir]=='asc'
      dir = 'ASC'
      @dir = '&dir=desc'
    else 
      dir = 'DESC'
      @dir = '&dir=asc'
    end
    order = params[:sort_by]!=nil ? " order by #{params[:sort_by]} #{dir}" : ''
    logger.debug "ORDER #{order}"
    if params[:admin]!=nil && @admin
      @lab=Lab.find(params[:id]) if params[:id]# try to get the selected lab
      @lab=Lab.first unless params[:id] # but if the parameter is not set, take the first lab
      #@vms=Vm.find(:all, :joins=>["vms inner join lab_vmts as l on vms.lab_vmt_id=l.id"], :order=>params[:sort_by])
      sql= Vm.find_by_sql("select vms.*, lab_vmts.lab_id from vms, lab_vmts where vms.lab_vmt_id=lab_vmts.id and lab_id=#{@lab.id} #{order}")
      @tab='admin'
      @labs=Lab.all.uniq
    else
      if params[:id]!=nil  # try to get the selected lab
         @lab=Lab.joins('labs inner join lab_users on lab_users.lab_id=labs.id').where('lab_id=? and user_id=?',params[:id], current_user.id).first
      else # but if the parameter is not set, take the first lab this user has   
         @lab=Lab.joins('labs inner join lab_users on lab_users.lab_id=labs.id').where('user_id=?', current_user.id).first
      end
      @labs=Lab.joins('labs inner join lab_users on lab_users.lab_id=labs.id').where('user_id=?', current_user.id).uniq
    end
    @vms= sql.paginate( :page => params[:page], :per_page => @per_page)
    render :action=>'index'
  end
  
   def vms_by_state
    @b_by='state'

    @state=params[:state] ? params[:state] : 'running'
    @state='stopped' if @state=='uninitialized'

    # TODO! turn it into DRY
    if params[:dir]=='asc'
      dir = 'ASC'
      @dir = '&dir=desc'
    else 
      dir = 'DESC'
      @dir = '&dir=asc'
    end
    order = params[:sort_by] ? " order by #{params[:sort_by]} #{dir}" : ''
  
    if params[:admin]!=nil && @admin
      @tab='admin'
      vms=Vm.find_by_sql("SELECT vms.*, lab_vmts.lab_id FROM vms INNER JOIN lab_vmts ON vms.lab_vmt_id=lab_vmts.id #{order}")
    else
      vms=Vm.find_by_sql("SELECT vms.*, lab_vmts.lab_id FROM vms INNER JOIN lab_vmts ON vms.lab_vmt_id=lab_vmts.id INNER JOIN lab_users ON vms.lab_user_id=lab_users.id INNER JOIN users ON lab_users.user_id=users.id WHERE lab_users.user_id=#{current_user.id} #{order}") 
    end
    @vm=[]
    vms.each do |vm|
      @vm.push(vm) if vm.state==@state
    end
    @vms=@vm.paginate(:page=>params[:page], :per_page=>@per_page)
    render :action=>'index'
  end
  
  # GET /vms
  # GET /vms.xml
  def index
    if params[:dir]=='asc'
      dir = 'ASC'
      @dir = '&dir=desc'
    else 
      dir = 'DESC'
      @dir = '&dir=asc'
    end
    order = params[:sort_by] ? " order by #{params[:sort_by]} #{dir}" : ''

    if params[:admin]!=nil && @admin
      sql= "SELECT vms.*, lab_vmts.lab_id from vms INNER JOIN lab_vmts ON vms.lab_vmt_id=lab_vmts.id #{order}"
      @tab='admin'
    else  
      sql= "select vms.*, lab_vmts.lab_id from vms INNER JOIN lab_vmts ON vms.lab_vmt_id=lab_vmts.id INNER JOIN lab_users on vms.lab_user_id=lab_users.id WHERE lab_users.user_id=#{current_user.id} #{order}"
    end
    @vms= Vm.paginate_by_sql(sql, :page => params[:page], :per_page => @per_page)
    
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @vms }
    end
  end

  # GET /vms/1
  # GET /vms/1.xml
  def show
   # @vm = Vm.find(params[:id])
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
    #@vm = Vm.find(params[:id])
  end

  
  # POST /vms
  # POST /vms.xml
  def create
    @vm = Vm.new(params[:vm])
  
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
    @vm = Vm.find(params[:id])

    respond_to do |format|
      if @vm.update_attributes(params[:vm])
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
    @vm = Vm.find(params[:id])
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
      @labuser = LabUser.find(params[:id])
      result = @labuser.vms_info
      format.html {redirect_to root_path, :notice => 'Permission error'}
      format.json {render :json=> { :success=> true, :vms=>result, :lab_user=> @labuser.id}}
    end
    rescue Timeout::Error
      respond_to do |format|        
        format.html {redirect_to :back , :notice => 'Permission error'}
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
        format.html {redirect_to :back , :notice => 'Permission error'}
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
      get_user
      if !@user
        logger.debug "Can't find user: "
        logger.debug params
        format.html { redirect_to :back , :notice=> "Can't find user" }
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
          format.html {redirect_to :back , :notice => result[:message].html_safe}
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
        format.html {redirect_to :back , :notice => '<br/>Starting all virtual machines failed, try starting them one by one.'}
        format.json {render :json=> { :success=> false, :message=>'Starting all virtual machines failed, try starting them one by one.', :lab_user=> @labuser.id}}
      end
    rescue ActiveRecord::RecordNotFound
      respond_to do |format|
        logger.debug "Can't find lab: "
        logger.debug params
        format.html { redirect_to my_labs_path , :notice=> "Can't find lab" }
        format.json { render :json=> {:success => false , :message=>  "Can't find lab" }}
      end
    rescue ActionController::RedirectBackError # cant redirect back? go to the lab instead
      logger.info "\nNo :back error\n"
      redirect_to(my_labs_path+'/'+@lab.id.to_s)

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
      
      format.html  { redirect_to(:back) }
      format.json  { render :json => {:success=>is_notice, :message=> is_notice ? 'Machine started' : 'Machine start failed'} }
    end
    
    rescue ActionController::RedirectBackError  # cant redirect back? go to the lab instead
      logger.info "\nNo :back error\n"
      redirect_to(my_labs_path+'/'+@vm.lab_vmt.lab.id.to_s)
  end
  
  #resume machine from pause
  # view is restriced to logged in users, before filter finds vm and checks if owner/admin
  def resume_vm
    respond_to do |format|
      logger.debug "\n resume? \n "
      result = @vm.resume_vm
      # TODO! check if really resumed
      format.html  { redirect_to(:back, :notice=> result[:message].html_safe) }
      format.json  { render :json => {:success=>result[:success], :message=> result[:message]  } }
    end
    
    rescue ActionController::RedirectBackError  # cant redirect back? go to the lab instead
      logger.info "\nNo :back error\n"
      redirect_to(my_labs_path+'/'+@vm.lab_vmt.lab.id.to_s)
  end
  
  #pause a machine
  # view is restriced to logged in users, before filter finds vm and checks if owner/admin
  def pause_vm
    respond_to do |format|
      logger.debug "\n resume? \n "
      result = @vm.pause_vm
      # TODO! check if really paused
      format.html  { redirect_to(:back, :notice=> result[:message].html_safe) }
      format.json  { render :json => {:success=>result[:success], :message=> result[:message] } }
    end
    
    rescue ActionController::RedirectBackError  # cant redirect back? go to the lab instead
      logger.info "\nNo :back error\n"
      redirect_to(my_labs_path+'/'+@vm.lab_vmt.lab.id.to_s)
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
        format.html {redirect_to :back , :notice => 'Permission error'}
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
    get_user
    if !@user
      logger.debug "Can't find user: "
      logger.debug params
      format.html { redirect_to :back , :notice=> "Can't find user" }
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
        format.html {redirect_to :back , :notice => result[:message].html_safe}
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
      format.html {redirect_to :back , :notice => '<br/>Starting all virtual machines failed, try stoppping them one by one.'}
      format.json {render :json=> { :success=> false, :message=>'Starting all virtual machines failed, try stoppping them one by one.', :lab_user=> @labuser.id}}
    end
  rescue ActiveRecord::RecordNotFound
    respond_to do |format|
      logger.debug "Can't find lab: "
      logger.debug params
      format.html { redirect_to my_labs_path , :notice=> "Can't find lab" }
      format.json { render :json=> {:success => false , :message=>  "Can't find lab" }}
    end
  rescue ActionController::RedirectBackError # cant redirect back? go to the lab instead
    logger.info "\nNo :back error\n"
    redirect_to(my_labs_path+'/'+@lab.id.to_s)

end


  # Stop the machine, do not delete the vm row from the db
  # view is restriced to logged in users, before filter finds vm and checks if owner/admin
  def stop_vm
    respond_to do |format|
      logger.debug "\n resume? \n "
      result = @vm.stop_vm
      # TODO! check if really stopped
      format.html  { redirect_to(:back, :notice=> result[:message].html_safe) }
      format.json  { render :json => {:success=>result[:success], :message=> result[:message] } }
    end
    
    rescue ActionController::RedirectBackError  # cant redirect back? go to the lab instead
      logger.info "\nNo :back error\n"
      redirect_to(my_labs_path+'/'+@vm.lab_vmt.lab.id.to_s)
  end
  
  def rdp_reset
    respond_to do |format|
      logger.debug "\n reset rdp? \n "
      result = @vm.reset_rdp
      
      format.html  { redirect_to(:back, :notice=> result[:message]) }
      format.json  { render :json => {:success=>result[:success], :message=> result[:message] } }
    end
    
    rescue ActionController::RedirectBackError  # cant redirect back? go to the lab instead
      logger.info "\nNo :back error\n"
      redirect_to(my_labs_path+'/'+@vm.lab_vmt.lab.id.to_s)
  end

	def guacamole_initializer
		initializerUrl = @vm.guacamole_initializer
		respond_to do |format|
			format.html { redirect_to(initializerUrl); }
			format.json { render :json => { :success => true, :url => initializerUrl } }
		end
	rescue Exception => e
		respond_to do |format|
			format.html { redirect_to(not_found_path, :notice => e.message); }
			format.json { render :json => { :success => false, :message => e.message } }
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
      format.json  { render :json => result }
      else
        format.html  { redirect_to( not_found_path, :notice=> result[:message]) }
        format.json  { render :json => {:success=>result[:success], :message=> result[:message] } }
      end
    end
  end

   #redirect user if they are not admin or the machine owner but try to modify a machine
  def auth_as_owner
    unless current_user == @vm.lab_user.user or @admin
      respond_to do |format|
        #You don't belong here. Go away.
        format.html { redirect_to root_path , :notice=> 'Sorry, this machine doesnt belong to you!' }
        format.json { render :json=> {:success => false , :message=>  'Sorry, this machine does not belong to you!'} }
      end
    end
  end
private #----------------------------------------------------------------------------------
 
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
end

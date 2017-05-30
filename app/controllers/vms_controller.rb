class VmsController < ApplicationController

	before_filter :save_from_nil, :only => [:show, :start_vm, :stop_vm, :pause_vm, :resume_vm, :rdp_reset, :open_guacamole]
	before_filter :auth_as_owner, :only => [:show, :start_vm, :stop_vm, :pause_vm, :resume_vm, :rdp_reset, :open_guacamole]
	before_filter :vm_tab, :only => [:show, :index, :vms_by_lab, :vms_by_state]

	def index
		order = get_order
		if params[:admin] != nil and @admin
			@vms = Vm.paginate_by_sql(sql, :page => params[:page], :per_page => @per_page)
			@tab = 'admin'
		else
			@vms = Vm.joins(:lab_user).where('lab_users.user_id = ?', current_user.id).order(order).paginate(:page => params[:page], :per_page => @per_page)
		end

		respond_to do |format|
			format.html # index.html.erb
			format.json { render :xml => @vms }
		end
	end

	def labuser_vms
		@labuser = LabUser.find(params[:id])
		result = @labuser.vms_info
		respond_to do |format|
			format.json { render :json => { :success => true, :vms => result, :lab_user => @labuser.id } }
		end
	rescue ActiveRecord::RecordNotFound
		respond_to do |format|
			format.json { render :status => 404, :json => { :success => false, :message => 'Not found' } }
		end
	end

	def vms_by_lab
		@b_by = 'lab'
		order = get_order

		if params[:admin] != nil and @admin
			@labs = Lab.all.uniq
			@lab = params[:id] ? Lab.find(params[:id]) : Lab.first
			vms = Vm.joins(:lab_vmt).joins(lab_user: :lab).joins(lab_user: :user).where('lab_vmts.lab_id = ?', @lab.id).order(order)
			@tab = 'admin'
		else
			@labs = Lab.joins(:lab_user).where('lab_users.user_id = ?', current_user.id).uniq
			@lab = params[:id] ? Lab.find(params[:id]) : @labs.first
			vms = Vm.joins(:lab_vmt).joins(lab_user: :lab).join(:lab_user, :user).where('lab_vmts.lab_id = ? and lab_users.user_id = ?', @lab.id, current_user.id).order(order)
		end

		@vms = vms.paginate(:page => params[:page], :per_page => @per_page)

		render :action => 'index'
	end

	def vms_by_state
		@b_by = 'state'
		order = get_order
		@state = params[:state] ? params[:state] : 'running'

		if params[:admin] != nil and @admin
			@tab = 'admin'
			vms = Vm.joins(lab_user: :lab).joins(lab_user: :user).order(order)
		else
			vms = Vm.joins(lab_user: :lab).joins(lab_user: :user).where('lab_users.user_id=?', current_user.id).order(order);
		end

		@vms = vms.select { |vm| vm.state == @state }.paginate(:page => params[:page], :per_page => @per_page)

		render :action => 'index'
	end

	def start_all
		get_user

		respond_to do |format|
			@lab = Lab.find(params[:id])
			if !@user
				format.html { redirect_to :back, :notice => "Can't find user" }
				format.json { render :json => { :success => false, :message => "Can't find user" } }
			elsif !@admin && (params[:username] || params[:user_id])
				format.html { redirect_to my_labs_path+(params[:id] ? "/#{params[:id]}" : '') }
				format.json { render :json => { :success => false, :message => 'No permission error' } }
			else # ok, there is such lab, but does the user have it?
				@labuser = LabUser.where('lab_id=? and user_id=?', @lab.id, @user.id).last
				if @labuser #user has this lab
					success = true
					message = @labuser.start_all_vms.map do |name, message|
						if message
							"Failed to start <b>#{name}</b>: " + message
							success = false
						else
							"<b>#{name}</b> has been started"
						end
					end
					message = message.join('<br/>')
					format.html { redirect_to :back, :notice => message.html_safe }
					format.json { render :json => { :success => success, :message => message, :lab_user => @labuser.id } }
				else # no this user does not have this lab
					format.html { redirect_to my_labs_path, :notice => 'That lab was not assigned to this user!' }
					format.json { render :json => { :success => false, :message => 'That lab was not assigned to this user!' } }
				end
			end
		end
	rescue Timeout::Error
		respond_to do |format|
			format.html { redirect_to :back, :notice => '<br/>Starting all virtual machines failed, try starting them one by one.' }
			format.json { render :json => { :success => false, :message => 'Starting all virtual machines failed, try starting them one by one.', :lab_user => @labuser.id } }
		end
	rescue ActiveRecord::RecordNotFound
		respond_to do |format|
			format.html { redirect_to my_labs_path, :notice => "Can't find lab" }
			format.json { render :json => { :success => false, :message => "Can't find lab" } }
		end
	rescue ActionController::RedirectBackError
		redirect_to(my_labs_path+'/'+@lab.id.to_s)
	end

	def stop_all
		respond_to do |format|
			@lab = Lab.find(params[:id])
			get_user
			if !@user
				format.json { render :json => { :success => false, :message => "Can't find user" } }
			elsif !@admin && (params[:username] || params[:user_id])
				format.html { redirect_to my_labs_path + (params[:id] ? "/#{params[:id]}" : '') }
				format.json { render :json => { :success => false, :message => 'No permission error' } }
			else
				@labuser = LabUser.where('lab_id=? and user_id=?', @lab.id, @user.id).last
				if @labuser
					message = @labuser.stop_all_vms.map do |name, message|
						if message
							"Failed to stop <b>#{name}</b>: " + message
						else
							"<b>#{name}</b> has been stopped"
						end
					end
					message = message.join('<br/>')
					format.html { redirect_to :back, :notice => message.html_safe }
					format.json { render :json => { :success => true, :message => message, :lab_user => @labuser.id } }
				else
					format.html { redirect_to my_labs_path, :notice => 'That lab was not assigned to this user!' }
					format.json { render :json => { :success => false, :message => 'That lab was not assigned to this user!' } }
				end
			end
		end
	end

	def show
		respond_to do |format|
			format.html # show.html.erb
			format.json { render :json => @vm }
		end
	end

	def start_vm
		respond_to do |format|
			begin
				@vm.start_vm
				format.html { redirect_to(:back) }
				format.json { render :json => { :success => true, :message => 'Machine has been started' } }
			rescue Exception => e
				flash[:alert] = e
				format.html { redirect_to(:back) }
				format.json { render :json => { :success => false, :message => 'Failed to start machine' } }
			end
		end
	rescue ActionController::RedirectBackError
		redirect_to(my_labs_path + '/' + @vm.lab_vmt.lab.id.to_s)
	end

	def resume_vm
		respond_to do |format|
			begin
				@vm.resume_vm
				format.html { redirect_to(:back, :notice => 'Machine has been resumed') }
				format.json { render :json => { :success => true, :message => 'Machine has been resumed' } }
			rescue Exception => e
				format.html { redirect_to(:back, :notice => 'Failed to resume machine') }
				format.json { render :json => { :success => false, :message => 'Failed to resume machine' } }
			end
		end
	rescue ActionController::RedirectBackError
		redirect_to(my_labs_path + '/' + @vm.lab_vmt.lab.id.to_s)
	end

	def pause_vm
		respond_to do |format|
			begin
				@vm.pause_vm
				format.html { redirect_to(:back, :notice => 'Machine has been paused') }
				format.json { render :json => { :success => true, :message => 'Machine has been paused' } }
			rescue
				format.html { redirect_to(:back, :notice => 'Failed to pause machine') }
				format.json { render :json => { :success => false, :message => 'Failed to pause machine' } }
			end
		end
	rescue ActionController::RedirectBackError
		redirect_to(my_labs_path + '/' + @vm.lab_vmt.lab.id.to_s)
	end

	def stop_vm
		respond_to do |format|
			begin
				@vm.stop_vm
				format.html { redirect_to(:back, :notice => 'Machine has been stopped') }
				format.json { render :json => { :success => true, :message => 'Machine has been stopped' } }
			rescue
				format.html { redirect_to(:back, :notice => 'Failed to stop machine') }
				format.json { render :json => { :success => false, :message => 'Failed to stop machine' } }
			end
		end
	rescue ActionController::RedirectBackError
		redirect_to(my_labs_path+'/'+@vm.lab_vmt.lab.id.to_s)
	end

	def rdp_reset
		respond_to do |format|
			begin
				@vm.reset_rdp
				format.html { redirect_to(:back, :notice => 'Failed to reset RDP') }
				format.json { render :json => { :success => false, :message => 'RDP has been reset' } }
			rescue
				format.html { redirect_to(:back, :notice => 'Failed to reset RDP') }
				format.json { render :json => { :success => false, :message => 'Failed to reset RDP' } }
			end
		end
	rescue ActionController::RedirectBackError
		redirect_to(my_labs_path + '/' + @vm.lab_vmt.lab.id.to_s)
	end

	def open_guacamole # vm by id in params
		respond_to do |format|
			result = @vm.open_guacamole
			if result && result[:success]
				format.html {
					cookies[:GUAC_AUTH] = {
						value: result[:token],
						domain: result[:domain],
						path: URI(ITee::Application::config.guacamole[:url_prefix]).path
					}
					redirect_to(result[:url])
				}
				format.json { render :json => result }
			else
				format.html { redirect_to(not_found_path, :notice => result[:message]) }
				format.json { render :json => { :success => result[:success], :message => result[:message] } }
			end
		end
	end

 private

	def auth_as_owner
		unless current_user == @vm.lab_user.user or @admin
			respond_to do |format|
				# You don't belong here. Go away.
				format.html { redirect_to root_path, :notice => 'Sorry, this machine doesnt belong to you!' }
				format.json { render :json => { :success => false, :message => 'Sorry, this machine does not belong to you!' } }
			end
		end
	end

	def save_from_nil
		@vm = Vm.find_by_id(params[:id])
		unless @vm
			respond_to do |format|
				format.html { redirect_to(vms_path, :notice => 'Can\'t find machine' ) }
				format.json { render :json => { :success => false, :message => 'Can\'t find machine' } }
			end
		end
	end

	def get_user
		@user = current_user
		if @admin
			if params[:user_id]
				@user = User.where('id = ?', params[:user_id]).first
			elsif params[:username]
				@user = User.where('username = ?', params[:username]).first
			end
		end
	end

	def get_order
		order = ''
		field_map = { 'image' => 'lab_vmts.name', 'lab' => 'labs.name', 'user' => 'users.username' }
		field = field_map[params[:sort_by]]
		if field
			order = field
			if params[:desc]
				order += ' DESC'
			end
		end
		order
	end
end

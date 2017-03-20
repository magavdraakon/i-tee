class VirtualboxController < ApplicationController
	before_filter :authorise_as_admin
	before_filter :set_user, only: [:update_password, :remove_password]
	before_filter :virtualization_tab

	def index
		@vms = Virtualbox.get_machines(params[:state], params[:where])
	end

	def templates
		@vms = Virtualbox.get_machines('template', params[:where])
	end

	def vm_details
		@vm= Virtualbox.get_vm_info(params[:name])
	end

	def manage_vm
		if params[:name]
			vms = [ params[:name] ]
		else
			vms = params[:names]
		end

		messages = []
		errors = []

		vms.each do |vm|
			begin
				case params[:do]
				when 'start'
					Virtualbox.start_vm(vm)
					messages << "#{vm} successfully started"
				when 'stop'
					Virtualbox.stop_vm(vm)
					messages << "#{vm} successfully stopped"
				when 'pause'
					Virtualbox.pause_vm(vm)
					messages << "#{vm} successfully paused"
				when 'resume'
					Virtualbox.resume_vm(vm)
					messages << "#{vm} successfully resumed"
				when 'reset_rdp'
					Virtualbox.reset_vm_rdp(vm)
					messages << "#{vm} RDP successfully reset"
				when 'take_snapshot'
					Virtualbox.take_snapshot(vm)
					messages << "#{vm} snapshot successfully taken"
				else
					raise 'Unknown action'
				end
			rescue Exception => e
				errors << e.message
			end
		end

		if errors.count > 0
			messages << "<b>Errors:</b>"
			redirect_to :back, alert: (messages.join('</br>') + '<br/>' + errors.join('<br/>')).html_safe
		else
			redirect_to :back, notice: messages.join('</br>').html_safe
		end

	rescue ActionController::RedirectBackError
		redirect_to(virtualization_path)
	end

	def rdp_password
		# display view with a form (in the future will specify which machines to set the pw for)
	end

	def update_password
		if @user
			@user.set_rdp_password # set password for current user
			redirect_to rdp_password_path, notice: "a new RDP password has been set for #{@user.username}"
		end
	end

	def remove_password		
		if @user
			@user.unset_rdp_password # remove password for current user
			redirect_to rdp_password_path, notice: "RDP password unset for #{@user.username}"			
		end
	end

	def guacamole_initializer
		initializerUrl = Virtualbox.guacamole_initializer(params[:name], current_user)
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

	def open_guacamole
		respond_to do |format|
	      	result = Virtualbox.open_guacamole(params[:name], current_user)
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

private
	def set_user
		if params[:username] && @admin # admin may remove others passwords
			username = params[:username]
		else
			username = current_user.username
		end
		@user = User.where("username=?", username).first
		unless @user
			redirect_to rdp_password_path, alert: "#{@user.username} not found"
		end
	end

end

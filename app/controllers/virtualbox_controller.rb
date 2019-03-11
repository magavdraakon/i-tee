class VirtualboxController < ApplicationController
	before_action :authorise_as_admin
	before_action :set_user, only: [:update_password, :remove_password]
	before_action :virtualization_tab

	def index
		begin
			@vms = Virtualbox.get_machines(params[:state], params[:where])
		rescue Exception => e
			logger.error e
			redirect_to root_path, alert: e.message
		end
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
			flash[:alert] = messages.join('<br/>') + '<br/>' + errors.join('<br/>')
      redirect_back fallback_location: virtualization_path
		else
			flash[:notice] = messages.join('<br/>')
      redirect_back fallback_location: virtualization_path
		end
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

	# used in virtualbox tab

	def open_guacamole
		respond_to do |format|
	      	result = Virtualbox.open_guacamole(params[:name], current_user, true)
	      	if result && result[:success]
	      		format.html {
	        		# set cookie
	        		data = {
	          			value: result[:token],
				        #expires: 1.hour.from_now,
				        domain: result[:domain], #%w(rangeforce.com), # %w(.example.com .example.org)
				        path: URI(ITee::Application::config.guacamole[:url_prefix]).path,
				        #:secure,
				        #:httponly
	        		}
	        		Rails.logger.debug "setting guacamole cookie #{data.to_json}"
	        		cookies[:GUAC_AUTH] = data
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

	# open guacamole-lite
	def rdp_connection
		respond_to do |format|
			begin
				@readonly = false
	      @token = Virtualbox.open_rdp(params[:name], current_user, @readonly)
	      @ws_host = Rails.configuration.guacamole2["ws_host"]
	      format.html{
	        render 'vms/guacamole_view', layout: false
	      }
	    rescue Exception => e
	    	format.html{
	    		flash[:alert] = e.message
	        redirect_to virtualization_path
	      }
	    end
    end
	end
	# open guacamole-lit readonly (no mouse & keyboard)
	def readonly_connection
		respond_to do |format|
			begin
				@readonly = true
	      @token = Virtualbox.open_rdp(params[:name], current_user, @readonly)
	      @ws_host = Rails.configuration.guacamole2["ws_host"]
	      format.html{
	        render 'vms/guacamole_view', layout: false
	      }
      rescue Exception => e
	    	format.html{
	    		flash[:alert] = e.message
	        redirect_to virtualization_path
	      }
	    end
    end
	end

	def rdp_admin
		respond_to do |format|
			Virtualbox.set_admin(!params[:global].blank?)
      format.html{
        redirect_back fallback_location: virtualization_path
      }
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

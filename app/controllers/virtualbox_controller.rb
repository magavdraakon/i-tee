class VirtualboxController < ApplicationController
	before_filter :authorise_as_manager
	before_filter :set_user, only: [:update_password, :remove_password]
	before_filter :virtualization_tab

	def index

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

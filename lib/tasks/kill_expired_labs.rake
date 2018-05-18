namespace :expired_labs do
  desc "Ends & destroys labs that have expired (retention is up)"
  task :search_and_destroy => :environment do

  	# Find labs that have retention due
    lab_users = LabUser.where("retention_time < ?", Time.now)
    unless lab_users.any?
    	Rails.logger.info "No expired labs"
    else
    	Rails.logger.info "Found #{lab_users.count} expired labs"
    	ended_labs = 0
    	failed_labs = 0
    	failed_labusers = 0
    	lab_users.each do |lab_user|
    	  ret = lab_user.end_lab
    	  if ret[:success] == true
    	  	if lab_user.destroy
    	  	  ended_labs+=1
    	  	else
    	  		failed_labs+=1
    	  	end
    	  else
    	  	Rails.logger.warning "Unable to kill lab_user #{lab_user.id} labs"
    	  	failed_labusers+=1
    	  end
    	end
    	Rails.logger.info "Ended #{ended_labs} labs. #{failed_labs} failed labs, #{failed_labusers} failed labusers"
    end
  end
end

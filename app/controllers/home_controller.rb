class HomeController < ApplicationController
  before_filter :authorise_as_admin, :only=>[:system_info, :template_info, :jobs, :delete_job, :run_job]
  before_filter :home_tab, :except=>[:about]


  def index
  end

  def error_401
    
  end
  
  def system_info
  end
  
  def about
    @tab='home' if user_signed_in?
  end
  

  def jobs
    @jobs=Delayed::Job.all
  end

  def delete_job
    job=Delayed::Job.find_by_id(params[:id])
    job.destroy
    redirect_to :back
  end

  def run_job
    job=Delayed::Job.find_by_id(params[:id])
    job.invoke_job
    redirect_to :back
  end

  #this is a method that updates a lab_users progress
  #input parameters: ip (the machine, the report is about)
  #                  progress (the progress for the machine)
  def getprogress
    #render :layout => false
    #who sent the info? 
    @client_ip = request.remote_ip
    @remote_ip = request.env['HTTP_X_FORWARDED_FOR']
    
    #get the lab_user based on the ip aadress- get the vm with the given ip, get the vm-s lab_user
    # update the labuser.progress based on the input
    @target_ip=params[:target]
    if @target_ip==nil
      @target_ip='error'
    else
      if @target_ip==@client_ip #TODO- once the allowed ip range is known, update
        @progress=params[:progress]
        if @progress!=nil
          @progress.gsub!(/_/) do
            '<br/>'
          end
        end
        @mac=Mac.find_by_ip(@target_ip).first #find(:first, :conditions=>['ip=?', @target_ip])
        if @mac.vm!=nil
          #the mac exists and has a vm
          user=@mac.vm.user.id
          lab=@mac.vm.lab_vmt.lab.id
          @lab_user=LabUser.where('user_id=? and lab_id=?', user, lab).first
          if @lab_user!=nil
            #the vm helped find its lab_user
            @lab_user.progress=@progress
            @lab_user.save() 
            
          end#end labuser exists
        end#end vm exists
      else
      end#end the target sent the progress
    end
  end
  
  
  
  def template_info
  end
  
  def catcher
    flash[:notice] = 'Seems that the page you were looking for does not exist, so you\'ve been redirected here.'
    redirect_to :action => 'index'
  end

end

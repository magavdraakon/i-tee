class HomeController < ApplicationController
  before_filter :authorise_as_admin, :only=>[:backup, :export, :import, :system_info, :template_info, :jobs, :delete_job, :run_job]
  before_filter :home_tab, :except=>[:about]
  require 'zip'
  # ist labs and import/export links
  def backup 
    @labs = Lab.all
    @import = ImportLabs.list_importable_labs
    logger.debug "\nimport labs: #{@import}\n"
  end

  # import from folder
  def import
    if params[:name]
      result =ImportLabs.import_from_folder(params[:name])
      if result
        if result[:success]
          redirect_to backup_path, notice: result[:message]
        else
          redirect_to backup_path, alert: result[:message]
        end
      else
        redirect_to backup_path, alert: 'import failed unexpectedly'
      end
    else
      redirect_to backup_path, alert: 'No folder specified'
    end
  end

  # export to folder
  def export
    if params[:id]
      result = ImportLabs.export_lab(params[:id])

      logger.debug result 
      if result
        if result[:success]
          redirect_to backup_path, notice: result[:message]
        else
          redirect_to backup_path, alert: result[:message]
        end
      else
        redirect_to backup_path, alert: 'export failed unexpectedly'
      end
    else
      redirect_to backup_path, alert: 'No lab id specified'
    end
  end

  def download_export
    if params[:name]
      #Attachment name
      filename = params[:name]+'.zip'
      temp_file = Tempfile.new(filename)
      dir = Rails.configuration.export_location ? Rails.configuration.export_location : '/var/labs/exports'
      dirname =  dir+'/'+params[:name]
      begin
        #This is the tricky part
        #Initialize the temp file as a zip file
        input_filenames = ['lab.json', 'timestamp.txt', 'host.json', 'lab_vmts.json']
        Zip::OutputStream.open(temp_file) { |zos| }
       
        #Add files to the zip file as usual
        Zip::File.open(temp_file.path, Zip::File::CREATE) do |zip|
          #Put files in here
          input_filenames.each do |filename|
            # Two arguments:
            # - The name of the file as it will appear in the archive
            # - The original file, including the path to find it
            zip.add(filename, dirname + '/' + filename)
          end
        end
       
        #Read the binary data from the file
        zip_data = File.read(temp_file.path)
       
        #Send the data to the browser as an attachment
        #We do not send the file directly because it will
        #get deleted before rails actually starts sending it
        send_data(zip_data, :type => 'application/zip', :filename => filename)
      ensure
        #Close and delete the temp file
        temp_file.close
        temp_file.unlink
      end
    else 
      redirect_to backup_path, alert: 'No folder specified'
    end
  end

  def index
  end

  def error_401
    
  end
  def error_404
    render :layout => false
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
            @lab_user.save
            
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

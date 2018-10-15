class HomeController < ApplicationController
  before_action :authorise_as_admin, :only=>[:backup, :export, :import, :system_info, :template_info, :jobs, :delete_job, :run_job]
  before_action :home_tab, :except=>[:about]
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
      result =ImportLabs.import_from_folder(Base64.decode64(params[:name]))
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
      filename = Base64.decode64(params[:name]).gsub('.','')+'.zip'
      temp_file = Tempfile.new(filename)
      dir = Rails.configuration.export_location ? Rails.configuration.export_location : '/var/labs/exports'
      dirname =  dir+'/'+Base64.decode64(params[:name])
      begin
        #This is the tricky part
        #Initialize the temp file as a zip file
        input_filenames = ['lab.json', 'timestamp.txt', 'lab_vmts.json']
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


  def ping 
    history = (params[:ph].blank? ? [] : params[:ph].values )
    if !params[:start].blank? && !params[:end].blank?
      history << {start_at: params[:start], end_at: params[:end]}
    end
    endping = false
    # save to DB
    if history.count >= 10
      if params[:token].blank?
        logger.error "unable to save ping statistics without a token"
      else
        labuser = LabUser.where(token: params[:token]).first
        if labuser
          if labuser.labuser_connections.create(history)
            history = [] # empty after save
            labuser.last_activity = Time.now
            labuser.activity = "ping"
            labuser.save
          end
        else
          history = [] # no use remembering info for token that does not match any labuser (lab ended?)
          endping = true
          logger.error "unable to find labuser with token #{params[:token]}"
        end
      end
    end
    respond_to do |format|
      format.html  { render :layout => false }
      format.json  { render :json => {ping: 'pong', ph: history, start: params[:time], end: endping } }
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
    @level = Rails.logger.level
    logger.info "LOG LEVEL IS #{@level}"
    @levels = [['debug',0],['info',1],['warn',2],['error',3],['fatal',4]]
    unless params[:loglevel].blank?
      level = params[:loglevel].to_i
      logger.info "CHANGE LOG LEVEL to #{level}"
      if level>=0 && level<=4
        Rails.logger.level = level
        redirect_to system_path, notice: "Log level changed"
      else
        redirect_to system_path, alert: "Unknown log level"
      end
    end
  end
  
  def about
    @tab='home' if user_signed_in?
  end
  

  def jobs
    @jobs=Delayed::Job.all
  end

  def delete_job
    job = Delayed::Job.find_by_id(params[:id])
    job.destroy
    redirect_back fallback_location: jobs_path
  end

  def run_job
    job = Delayed::Job.find_by_id(params[:id])
    job.invoke_job
    redirect_back fallback_location: jobs_path
  end

  def template_info
  end
  
  def check_resources
    result = Check.has_free_resources
    respond_to do |format|
      format.html  {redirect_to root_path, :notice=>'Seems that the page you were looking for does not exist, so you\'ve been redirected here.' }
      format.json  { render :json => result }
    end
  end

  def catcher
    respond_to do |format|
      format.html  {redirect_to root_path, :notice=>'Seems that the page you were looking for does not exist, so you\'ve been redirected here.' }
      format.json  { render :json => {:success=>false, :message=>"missing endpoint"} }
    end
  end

end

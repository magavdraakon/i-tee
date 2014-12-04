if ITee::Application::config.respond_to? :run_dir then
  path="#{ITee::Application.config.run_dir}/environment.sh"
else
  path='/var/labs/environment.sh'
end




begin
File.open(path, "w+") { |f|
  f.write("export RAILSROOT='#{Rails.root}'\n")


  if ITee::Application::config.respond_to? :cmd_perfix then
    exec_line = ITee::Application::config.cmd_perfix
  else
    exec_line = "sudo -u vbox "
  end

  f.write("export CMD_LINE='#{exec_line}'\n")


  if ITee::Application::config.respond_to? :run_dir then
    run_dir = ITee::Application::config.run_dir
  else
    run_dir = '/var/labs'
  end

  f.write("export RUNDIR='#{run_dir}'\n")
}
rescue
  Rails.logger.error("Can't open file #{path} for writing!")
else
  Rails.logger.info("Writing configuration to #{path}")
end

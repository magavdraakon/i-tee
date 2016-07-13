ITee::Application.configure do
  # Settings specified here will take precedence over those in config/environment.rb
  
  #emulate_virtualization = true means that eucalyptus virtualization evnironment is't installed
  config.emulate_virtualization = false
  config.emulate_ldap = false

  # determine how many instances are shown per page
  config.per_page=15

  # determine what layout to use
  config.default_skin = 'EIK'
  config.skins = { 'host1'=> 'EIK'}

  #Administrator and manager usernames
  config.admins = ['admin1','admin2']
  config.managers = ['manager1']

  # hostname for rdp sessions
  config.rdp_host = '192.168.13.12'
  # port prefix for rdp sessions
  config.rdp_port_prefix = '10'
  config.rdp_password_length = 14

  #place for temporal files like VM customization files
  config.run_dir = '/var/labs/run'
  # place for lab export / import jsons
  config.export_location= '/var/labs/exports'

  #environment for bash scripts executed by rails
  ENV['ENVIRONMENT']="#{ITee::Application.config.run_dir}/environment.sh"

  # Virtualbox user and command line for launching scripts
  config.cmd_perfix = 'sudo -Hu vbox'

  # Location for exported labs
  config.export_location = '/var/labs/export'

  # set log level to debug for development env
  config.log_level = :debug

  # In the development environment your application's code is reloaded on
  # every request.  This slows down response time but is perfect for development
  # since you don't have to restart the webserver when you make code changes.
  config.cache_classes = false

  # Log error messages when you accidentally call methods on nil.
  config.whiny_nils = true

  # Show full error reports and disable caching
  config.consider_all_requests_local       = true
  #config.action_view.debug_rjs             = true
  config.action_controller.perform_caching = false

  # Don't care if the mailer can't send
  config.action_mailer.raise_delivery_errors = false

  # Print deprecation notices to the Rails logger
  config.active_support.deprecation = :log

  # Only use best-standards-support built into browsers
  config.action_dispatch.best_standards_support = :builtin
end


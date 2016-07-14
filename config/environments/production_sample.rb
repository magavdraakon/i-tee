require 'yaml'

ITee::Application.configure do

  configFile = { }

  # .yaml is recommended extensions, so let's use that
  if File.exist?('/etc/i-tee/config.yaml')
    configFile = YAML.load_file("/etc/i-tee/config.yaml")
  end

  # Settings specified here will take precedence over those in config/environment.rb

  # The production environment is meant for finished, "live" apps.
  # Code is not reloaded between requests
  config.cache_classes = true

  # Full error reports are disabled and caching is turned on
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  # Specifies the header that your server uses for sending files
  config.action_dispatch.x_sendfile_header = 'X-Sendfile'

  # Administrator and manager usernames
  config.admins = configFile.key?('admins') ? configFile['admins'] : [ ]
  config.managers = configFile.key?('managers') ? configFile['managers'] : [ ]

  # hostname for rdp sessions
  config.rdp_host = configFile['rdp_host'] #'elab.itcollege.ee'
  # port prefix for rdp sessions
  config.rdp_port_prefix = configFile.key?('rdp_port_prefix') ? configFile['rdp_port_prefix'] : '10'
  config.rdp_password_length = 14

   # determine how many instances are shown per page
  config.per_page=15

  # determine what layout to use
  config.default_skin = configFile.key?('skin') ? configFile['skin'] : 'EIK'
  config.skins = { 'host1'=> 'EIK'}

  # place for temporal files like VM customization files
  config.run_dir = '/var/labs/run'
  # place for lab export / import jsons
  config.export_location= '/var/labs/exports'

  # envidonment for bash scripts executed by rails
  ENV['ENVIRONMENT']="#{ITee::Application.config.run_dir}/environment.sh"

  # Virtualbox user and command line for launching scripts
  config.cmd_perfix = 'sudo -Hu vbox'

  # For nginx:
  # config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect'

  # If you have no front-end server that supports something like X-Sendfile,
  # just comment this out and Rails will serve the files

  # See everything in the log (default is :info)
  if configFile.key?('debug') && configFile['debug']
    config.log_level = :debug
  end

  # Use a different logger for distributed setups
  # config.logger = SyslogLogger.new

  # Use a different cache store in production
  # config.cache_store = :mem_cache_store

  # Disable Rails's static asset server
  # In production, Apache or nginx will already do this
  config.serve_static_assets = false

  # Enable serving of images, stylesheets, and javascripts from an asset server
  # config.action_controller.asset_host = "http://assets.example.com"

  # Disable delivery errors, bad email addresses will be ignored
  # config.action_mailer.raise_delivery_errors = false

  # Enable threaded mode
  # config.threadsafe!

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation can not be found)
  config.i18n.fallbacks = true

  # Send deprecation notices to registered listeners
  config.active_support.deprecation = :notify
end

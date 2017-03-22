require 'yaml'

ITee::Application.configure do

  config.serve_static_assets = false
  config.i18n.fallbacks = true
  config.action_dispatch.x_sendfile_header = 'X-Sendfile'
  config.active_support.deprecation = :notify
  config.logger = Logger.new(STDOUT)
  config.per_page=15

  config_file = { }

  # .yaml is recommended extensions, so let's use that
  if File.exist?('/etc/i-tee/config.yaml')
    config_file = YAML.load_file("/etc/i-tee/config.yaml")
  end


  # Administrator and manager usernames
  config.admins = config_file.key?('admins') ? config_file['admins'] : [ ]
  config.managers = config_file.key?('managers') ? config_file['managers'] : [ ]

  # Outside root URL of I-Tee instance (e.g. https://localhost:8880/i-tee)
  config.application_url = config_file['application_url']

  # hostname for rdp sessions
  config.rdp_host = config_file['rdp_host']
  config.rdp_password_length = 14

  # Layout to use
  config.skin = config_file.key?('skin') ? config_file['skin'] : 'EIK'

  # place for lab export / import jsons
  config.export_location = '/var/labs/exports'

  # Guacamole configuration
  if config_file.key?('guacamole')
    config.guacamole = {
      # Guacamole initializer
      initializer_url: config_file['guacamole']['initializer_url'],
      initializer_key: config_file['guacamole']['initializer_key'],
    }

    if config_file['guacamole'].key?('rdp_host')

      # I-Tee host used by Guacamole to connect to machines via RDP (e.g. localhost)
      config.guacamole[:rdp_host] = config_file['guacamole']['rdp_host']

    end
  end


  if config_file.key?('development') && config_file['development']

    # Code is not reloaded between requests
    config.cache_classes = false

    # Log level (defaults to :info)
    config.log_level = :debug

    # Full error reports are disabled and caching is turned on
    config.consider_all_requests_local       = true
    config.action_controller.perform_caching = false

  else

    # Code is not reloaded between requests
    config.cache_classes = true

    # Log level (defaults to :info)
    config.log_level = :info

    # Full error reports are disabled and caching is turned on
    config.consider_all_requests_local       = false
    config.action_controller.perform_caching = true

  end
end

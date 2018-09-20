require 'yaml'
Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Eager load code on boot. This eager loads most of Rails and
  # your application in memory, allowing both threaded web servers
  # and those relying on copy on write to perform better.
  # Rake tasks automatically ignore this option for performance.
  config.eager_load = true

  # Ensures that a master key has been made available in either ENV["RAILS_MASTER_KEY"]
  # or in config/master.key. This key is used to decrypt credentials (and other encrypted files).
  # config.require_master_key = true

  # Disable serving static files from the `/public` folder by default since
  # Apache or NGINX already handles this.
  config.public_file_server.enabled = ENV['RAILS_SERVE_STATIC_FILES'].present?

  # Compress JavaScripts and CSS.
  config.assets.js_compressor = :uglifier
  # config.assets.css_compressor = :sass


  # `config.assets.precompile` and `config.assets.version` have moved to config/initializers/assets.rb

  # Enable serving of images, stylesheets, and JavaScripts from an asset server.
  # config.action_controller.asset_host = 'http://assets.example.com'

  # Specifies the header that your server uses for sending files.
  # config.action_dispatch.x_sendfile_header = 'X-Sendfile' # for Apache
  # config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect' # for NGINX

  # Store uploaded files on the local file system (see config/storage.yml for options)
  config.active_storage.service = :local

  # Mount Action Cable outside main process or domain
  # config.action_cable.mount_path = nil
  # config.action_cable.url = 'wss://example.com/cable'
  # config.action_cable.allowed_request_origins = [ 'http://example.com', /http:\/\/example.*/ ]

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  # config.force_ssl = true


  # Prepend all log lines with the following tags.
  config.log_tags = [ :request_id ]

  # Use a different cache store in production.
  # config.cache_store = :mem_cache_store

  # Use a real queuing backend for Active Job (and separate queues per environment)
  # config.active_job.queue_adapter     = :resque
  # config.active_job.queue_name_prefix = "i_tee_#{Rails.env}"

  # Ignore bad email addresses and do not raise email delivery errors.
  # Set this to true and configure the email server for immediate delivery to raise delivery errors.
  # config.action_mailer.raise_delivery_errors = false

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation cannot be found).
  config.i18n.fallbacks = true

  # Send deprecation notices to registered listeners.
  config.active_support.deprecation = :notify

  # Use default logging formatter so that PID and timestamp are not suppressed.
  config.log_formatter = ::Logger::Formatter.new

  # Use a different logger for distributed setups.
  # require 'syslog/logger'
  # config.logger = ActiveSupport::TaggedLogging.new(Syslog::Logger.new 'app-name')

  if ENV["RAILS_LOG_TO_STDOUT"].present?
    logger           = ActiveSupport::Logger.new(STDOUT)
    logger.formatter = config.log_formatter
    config.logger    = ActiveSupport::TaggedLogging.new(logger)
  end

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false



##############################  
  config_file = { }
  # .yaml is recommended extensions, so let's use that
  if File.exist?('/etc/i-tee/config.yaml')
    config_file = YAML.load_file("/etc/i-tee/config.yaml")
  

    # take vbox config
    config.vbox = config_file.key?('vbox') ? config_file['vbox'] : false


    config.allowed_origins = config_file.key?('allowed_origins') ? config_file['allowed_origins'] : [ 'https://'+config_file['rdp_host'] ]

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
    # pagination limits
    config.per_page = config_file.key?('per_page') ? config_file['per_page'] :15



    

  

    # Database connection configurations for I-Tee and Guacamole databases
    config.database = {
      "production" => config_file['database'],
      "production_guacamole" => config_file['guacamole_database'] # used in app/models/guaccamole_db_base
    }
    # used in config/database.yml
    ENV["ITEE_HOST"] = config_file['database']['host']
    ENV["ITEE_USER"] = config_file['database']['username']
    ENV["ITEE_PASSWORD"] = config_file['database']['password']
    ENV["ITEE_DATABASE"] = config_file['database']['database']


    ENV["GUACAMOLE_DB_HOST"] = config_file['guacamole_database']['host']
    ENV["GUACAMOLE_DB_USER"] = config_file['guacamole_database']['username']  
    ENV["GUACAMOLE_DB_PASSWORD"] = config_file['guacamole_database']['password']
    ENV["GUACAMOLE_DB_NAME"] = config_file['guacamole_database']['database']

    # LDAP authentication configuration
    config.ldap = {
      "host" => config_file['ldap']['host'],
      "port" => config_file['ldap']['port'],
      "attribute" => config_file['ldap'].key?('attribute') ? config_file['ldap']['attribute'] : 'uid',
      "base" => config_file['ldap']['base'],
      "ssl" => config_file['ldap']['ssl'] ? true : false,
      "admin_user" => config_file['ldap']['user'],
      "admin_password" => config_file['ldap']['password'],
      "group_base" => config_file['ldap']['group_base'],
      "require_attribute" => {
        "objectClass" => 'inetOrgPerson',
        "authorizationRole" => 'postsAdmin'
      }
    }

    # Guacamole configuration
    if config_file.key?('guacamole')
      config.guacamole = {

        # Domain name set to Guacamole authentication cookie
        cookie_domain: config_file['guacamole'].key?('cookie_domain') ?
                      config_file['guacamole']['cookie_domain'] : '',

        # Guacamole username prefix
        user_prefix: config_file['guacamole'].key?('prefix') ?
                    config_file['guacamole']['prefix'] : 'dev',

        # Full url to Guacamole API endpoints (e.g. https://localhost/guacamole)
        url_prefix: config_file['guacamole']['url_prefix'],

        max_connections: 5,
        max_connections_per_user: 2
      }

      if config_file['guacamole'].key?('rdp_host')

        # I-Tee host used by Guacamole to connect to machines via RDP (e.g. localhost)
        config.guacamole[:rdp_host] = config_file['guacamole']['rdp_host']

      end
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

    if config_file.key?('log_level') && ['fatal','error','info','warn','debug'].include?(config_file['log_level'])
      config.log_level = config_file['log_level'].to_sym
    else
      # Log level (defaults to :info)
      config.log_level = :info
    end

    # Full error reports are disabled and caching is turned on
    config.consider_all_requests_local       = false
    config.action_controller.perform_caching = true

    # Compress JavaScripts and CSS
    config.assets.compress = true  # TODO! check if this is needed
    
    config.assets.compile = false
    
    # Generate digests for assets URLs.
    config.assets.digest = true

  end
  # place for lab export / import jsons
  config.export_location = '/var/labs/exports'
end

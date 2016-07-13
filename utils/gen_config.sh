#!/usr/bin/env bash
# Author Margus Ernits
# License MIT

if [ $UID -ne 0 ]
then
    echo "use sudo $0"
    exit 1
fi

hostname -f || {

echo "hostname -f did not return proper FQDN"
echo "Please edit /etc/hostname and /etc/hosts file to correct the problem"
exit 1

}

if [[ -r /var/www/railsapps/i-tee/config/environments/production.rb  ]]
then
    echo "Configuration exists! Exiting ..."
    exit 1
else
cat > /var/www/railsapps/i-tee/config/environments/production.rb << END
ITee::Application.configure do
  config.emulate_virtualization = false
  config.emulate_ldap = false

  config.use_libvirt = true
  # Settings specified here will take precedence over those in config/environment.rb

  # The production environment is meant for finished, "live" apps.
  # Code is not reloaded between requests
  config.cache_classes = true

  # Full error reports are disabled and caching is turned on
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  # Specifies the header that your server uses for sending files
  config.action_dispatch.x_sendfile_header = "X-Sendfile"

   #Administrator and manager usernames
  config.admins = ['mernits','ttanav','kloodus','jaanus']
  config.managers = ['robot']

  # determine how many instances are shown per page
  config.per_page=150

  # determine what layout to use
  config.default_skin = 'EIK'
  config.skins = { '$(hostname -f)'=> 'EIK', 'livex.vequrity.com'=>'vequrity', 'livedemo.vequrity.com'=>'vequrity'}

  # hostname for rdp sessions
  #config.rdp_host = 'i-tee.itcollege.ee'
  config.rdp_host = '$(hostname -f)'
  # port prefix for rdp sessions
  config.rdp_port_prefix = '10'

  #place for temporar files like VM customization files
  config.run_dir = '/var/labs/run'

  #envidonment for bash scripts executed by rails
  ENV['ENVIRONMENT']="#{ITee::Application.config.run_dir}/environment.sh"

  #Virtualbox User and command line for launching scripts
  config.cmd_perfix = 'sudo -Hu vbox '


  # For nginx:
  # config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect'

  # If you have no front-end server that supports something like X-Sendfile,
  # just comment this out and Rails will serve the files

  # See everything in the log (default is :info)
   config.log_level = :debug
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

END
fi


#TODO generate ldap config

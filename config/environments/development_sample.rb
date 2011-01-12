ITee::Application.configure do
  # Settings specified here will take precedence over those in config/environment.rb
  
  #emulate_virtualization = true means that eucalyptus virtualization evnironment is't installed
  config.emulate_virtualization = false
  config.emulate_eucalyptus = true
  config.emulate_ldap = false
  config.use_libvirt = true

  #eycalyptus aws information
  config.ec2_url = 'http://192.168.13.13:8773/services/Eucalyptus'
  config.access_key = '95cPcqlup5jNLhxtY6NxzIkzcthow5ZpA6xNBg'
  config.secret_key = '8NPspBnqoCQM4kKhQ98TAsd2rLZ8R0lZzdnm7g'

  #Administrator usernames
  config.admins = ['mernits','matoom','ttanav','admin']

  # In the development environment your application's code is reloaded on
  # every request.  This slows down response time but is perfect for development
  # since you don't have to restart the webserver when you make code changes.
  config.cache_classes = false

  # Log error messages when you accidentally call methods on nil.
  config.whiny_nils = true

  # Show full error reports and disable caching
  config.consider_all_requests_local       = true
  config.action_view.debug_rjs             = true
  config.action_controller.perform_caching = false

  # Don't care if the mailer can't send
  config.action_mailer.raise_delivery_errors = false

  # Print deprecation notices to the Rails logger
  config.active_support.deprecation = :log

  # Only use best-standards-support built into browsers
  config.action_dispatch.best_standards_support = :builtin
end
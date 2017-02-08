module AppVersion
  APP_VERSION = `cat version.txt 2>/dev/null || echo "(version unavailable)"`
  PLATFORM_INFO = "Ruby: #{RUBY_ENGINE}-#{RUBY_VERSION}-p#{RUBY_PATCHLEVEL}, Rails: #{Rails.version}"
end

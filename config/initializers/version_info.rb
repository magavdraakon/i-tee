module AppVersion
  GIT_REVISION = `git log --pretty=format:'%h' -n 1`
  APP_VERSION = `[ -f version.txt ] && cat version.txt || echo "NO VERSION INFO"`
  PLATFORM_INFO = "Ruby: #{RUBY_ENGINE}-#{RUBY_VERSION}-p#{RUBY_PATCHLEVEL}, Rails: #{Rails.version}"
end
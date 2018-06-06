# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = '1.0'

# Add additional assets to the asset load path
# Rails.application.config.assets.paths << Emoji.images_path

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in app/assets folder are already added.
# Rails.application.config.assets.precompile += %w( search.js )

all_controllers =  Dir[
    Rails.root.join('app/controllers/*_controller.rb')
  ].map { |path|
    path.match(/(\w+)_controller.rb/); $1
  }.compact
# add devise controllers
all_controllers+=  Dir[
    Rails.root.join('app/controllers/user/*_controller.rb')
  ].map { |path|
    path.match(/(\w+)_controller.rb/); "user/#{$1}"
  }.compact

all_controllers.each do |controller|
  Rails.application.config.assets.precompile += ["#{controller}.js", "#{controller}.css"]
end

all_layouts =  Dir[
    Rails.root.join('app/assets/stylesheets/*_layout.*')
  ].map { |path|
    path.match(/(\w+)_layout.*/); $1
  }.compact

# layouts
all_layouts.each do |layout|
  Rails.application.config.assets.precompile += ["#{layout}_layout.js", "#{layout}_layout.css"]
end

Rails.application.config.assets.precompile += ['marked.css', "reset.css", 'prettify.js', 'prettify.css', 'EIK.css', 'vequrity.css']
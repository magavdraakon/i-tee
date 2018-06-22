FROM ruby:2.2.5
MAINTAINER margus.ernits@rangeforce.com

RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends build-essential sudo openssh-client libyaml-0-2 libgmp-dev libmysqlclient-dev libsqlite3-dev bundler nodejs \
    && apt-get clean autoclean \
    && apt-get autoremove -y \
    && rm -rf  /var/lib/apt  /var/lib/dpkg  /var/lib/cache /var/lib/log \
    && mkdir -p /var/run/sshd /var/labs/run

WORKDIR /var/www/i-tee

# Setting env up
ENV RAILS_ENV='production'
ENV RAKE_ENV='production' 
# Adding gems
COPY /Gemfile /var/www/i-tee/Gemfile
COPY /Gemfile.lock /var/www/i-tee/Gemfile.lock

RUN bundle install --jobs 20 --retry 5 --without development test 
# Adding project files

COPY /Rakefile /var/www/i-tee/Rakefile
COPY /config.ru /var/www/i-tee/config.ru
COPY /lib/ /var/www/i-tee/lib/
COPY /script/ /var/www/i-tee/script/
COPY /public/ /var/www/i-tee/public/
COPY /config/ /var/www/i-tee/config/
COPY /db/ /var/www/i-tee/db/
COPY /utils/ /var/www/i-tee/utils/
COPY /app/ /var/www/i-tee/app/
COPY /version.txt /var/www/i-tee/version.txt

COPY /docker/vboxmanage /var/www/i-tee/utils/vboxmanage
COPY /docker/check-resources /var/www/i-tee/utils/check-resources
COPY /docker/application.rb /var/www/i-tee/config/application.rb
COPY /docker/devise.rb /var/www/i-tee/config/initializers/devise.rb
COPY /docker/production.rb /var/www/i-tee/config/environments/production.rb

RUN RAILS_ENV=production bundle exec rake SECRET_KEY_BASE=for_asset_build  assets:precompile
EXPOSE 80
CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]


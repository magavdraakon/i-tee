FROM ruby:2.2.5
MAINTAINER margus.ernits@rangeforce.com

RUN apt-get update && \
    apt-get install -y --no-install-recommends sudo openssh-client libyaml-0-2 libgmp-dev libmysqlclient-dev libsqlite3-dev bundler nodejs cron screen \
    && apt-get clean autoclean \
    && apt-get autoremove -y \
    && rm -rf  /var/lib/apt  /var/lib/dpkg  /var/lib/cache /var/lib/log \
    && mkdir -p /var/run/sshd /var/labs/run


WORKDIR /var/www/i-tee
ENV RAILS_ENV=production
COPY /Gemfile /var/www/i-tee/Gemfile
COPY /Gemfile.lock /var/www/i-tee/Gemfile.lock
RUN gem install bundler && bundle install --jobs 20 --retry 5

COPY /Rakefile /var/www/i-tee/Rakefile
COPY /config.ru /var/www/i-tee/config.ru
COPY /lib/ /var/www/i-tee/lib/
COPY /script/ /var/www/i-tee/script/
COPY /public/ /var/www/i-tee/public/
COPY /config/ /var/www/i-tee/config/
COPY /db/ /var/www/i-tee/db/
COPY /utils/ /var/www/i-tee/utils/
COPY /app/ /var/www/i-tee/app/
#COPY /install/etc/cron.d/expired_labs /etc/cron.d/expired_labs
COPY /version.txt /var/www/i-tee/version.txt

COPY /docker/vboxmanage /var/www/i-tee/utils/vboxmanage
COPY /docker/check-resources /var/www/i-tee/utils/check-resources
COPY /docker/application.rb /var/www/i-tee/config/application.rb
COPY /docker/devise.rb /var/www/i-tee/config/initializers/devise.rb
COPY /docker/production.rb /var/www/i-tee/config/environments/production.rb

RUN echo "* * * * * . /etc/environment && bash -c 'cd /var/www/i-tee/ && rake RAILS_ENV=production expired_labs:search_and_destroy > /var/www/i-tee/cron.log 2>&1'" | crontab -

EXPOSE 80

ENTRYPOINT env >> /etc/environment && /usr/bin/screen -dmS cronjob /usr/sbin/cron -f; /usr/local/bundle/bin/passenger start -p 80 -e production --log-file /dev/stderr --min-instances 10 --max-pool-size 30

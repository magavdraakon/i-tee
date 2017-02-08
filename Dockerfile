FROM ruby:2.2.5
MAINTAINER keijo.kapp@rangeforce.com

RUN apt-get update && \
    apt-get install -y --no-install-recommends sudo openssh-client libyaml-0-2 libgmp-dev libmysqlclient-dev libsqlite3-dev && \
    gem install bundler && \
    mkdir -p /var/run/sshd /var/labs/run

COPY /docker/vboxmanage /usr/local/bin/vboxmanage
RUN ln -s /usr/local/bin/vboxmanage /usr/bin/VBoxManage

WORKDIR /var/www/i-tee
ENV RAILS_ENV=production
COPY /Gemfile /var/www/i-tee/Gemfile
COPY /Gemfile.lock /var/www/i-tee/Gemfile.lock
RUN bundle install

COPY /version.txt /var/www/i-tee/version.txt
COPY /Rakefile /var/www/i-tee/Rakefile
COPY /config.ru /var/www/i-tee/config.ru
COPY /public/ /var/www/i-tee/public/
COPY /app/ /var/www/i-tee/app/
COPY /config/ /var/www/i-tee/config/
COPY /db/ /var/www/i-tee/db/
COPY /lib/ /var/www/i-tee/lib/
COPY /script/ /var/www/i-tee/script/
COPY /test/ /var/www/i-tee/test/
COPY /utils/ /var/www/i-tee/utils/

COPY /docker/application.rb /var/www/i-tee/config/application.rb
COPY /docker/devise.rb /var/www/i-tee/config/initializers/devise.rb
COPY /docker/production.rb /var/www/i-tee/config/environments/production.rb

RUN groupadd -og 0 vboxusers && useradd -Md /root -g vboxusers -ou 0 vbox

EXPOSE 80

ENTRYPOINT [ "/usr/local/bundle/bin/passenger", "start", "-p", "80", "-e", "production", "--log-file", "/dev/stderr" ]


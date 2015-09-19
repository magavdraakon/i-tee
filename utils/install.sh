#!/usr/bin/env bash
# Author Margus Ernits
# License MIT


#TODO detect OS version

sudo apt-get update

sudo apt-get dist-upgrade

sudo apt-get install linux-headers-$(uname -r) build-essential dkms -y

sudo apt-get install unzip git htop -y
sudo apt-get install makepasswd -y



#Add virtualbox apt source to software sources list:

echo "deb http://download.virtualbox.org/virtualbox/debian trusty contrib" \
 > /etc/apt/sources.list.d/virtualbox.list


#Download and import Oracle VirtualBox public key:

wget -q http://download.virtualbox.org/virtualbox/debian/oracle_vbox.asc \
 -O- | sudo apt-key add -


apt-get update


apt-get install virtualbox-5.0 -y


VBoxManage extpack uninstall "Oracle VM VirtualBox Extension Pack"
su - vbox -c'vboxmanage extpack uninstall "Oracle VM VirtualBox Extension Pack"'

VER=$(apt-cache policy virtualbox-5.0 |grep Installed:| cut -f2 -d: |cut -f1 -d-|cut -f2 -d' ')
SUBVER=$(apt-cache policy virtualbox-5.0 |grep Installed:| cut -f2 -d: |cut -f1 -d~|cut -f2 -d' ')

echo $VER
echo $SUBVER

wget http://download.virtualbox.org/virtualbox/${VER}/Oracle_VM_VirtualBox_Extension_Pack-${SUBVER}.vbox-extpack
VBoxManage extpack install Oracle_VM_VirtualBox_Extension_Pack-${SUBVER}.vbox-extpack


VBoxManage list extpacks

#TODO add password generation for vbox
adduser  --disabled-password vbox
adduser vbox vboxusers

usermod -d /var/labs -m vbox

cat > /etc/default/virtualbox << EOF
VBOXWEB_USER=vbox
VBOXAUTOSTART_DB=/etc/vbox
VBOXAUTOSTART_CONFIG=/etc/vbox/auto.cfg
EOF


cat > /etc/vbox/auto.cfg << EOF
default_policy = deny
vbox = {
        allow = true
        startup_delay = 10
}
EOF

su - vbox -c'VBoxManage setproperty autostartdbpath /etc/vbox'
chgrp vboxusers /etc/vbox

grep vbox /etc/default/virtualbox

update-rc.d vboxweb-service defaults
service vboxweb-service start
sudo apt-get install nginx
ssh-keygen -f /etc/ssl/private/YOUR-FQDN.key
openssl req -new -key /etc/ssl/private/YOUR-FQDN.key \
     -out /root/YOUR-FQDN.req

openssl req -in /root/YOUR-FQDN.req -text -noout
openssl x509 -req -days 3650 -in /root/YOUR-FQDN.req -signkey /etc/ssl/private/YOUR-FQDN.key -out  /etc/ssl/certs/YOUR-FQDN.pem
openssl x509 -in /etc/ssl/certs/YOUR-FQDN.pem -text -noout


PHPVIRTUALBOX=5.0-2.zip

wget https://github.com/imoore76/phpvirtualbox/archive/$PHPVIRTUALBOX -O $PHPVIRTUALBOX

unzip $PHPVIRTUALBOX

cp -a /root/phpvirtualbox-$(basename $PHPVIRTUALBOX .zip) /usr/share/nginx/

ln -sf /usr/share/nginx/phpvirtualbox-$(basename $PHPVIRTUALBOX .zip) /usr/share/nginx/phpvirtualbox

chown www-data:www-data /usr/share/nginx/phpvirtualbox -R

cat > /etc/nginx/sites-available/i-tee << EOF
# HTTPS server
#
server {
    listen 4433;

    root /usr/share/nginx/phpvirtualbox;
    index index.php index.html index.htm;

    ssl on;
    ssl_certificate /etc/ssl/certs/YOUR-FQDN.pem;
    ssl_certificate_key /etc/ssl/private/YOUR-FQDN.key;

    ssl_session_timeout 5m;

    ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
    ssl_ciphers ALL:!ADH:!EXPORT56:RC4+RSA:+HIGH:+MEDIUM:+LOW:+SSLv3:+EXP;
    ssl_prefer_server_ciphers on;

    location / {
            try_files \$uri \$uri/ /index.html;
    }
    location ~ \.php$ {
           fastcgi_split_path_info ^(.+\.php)(/.+)$;
           # NOTE: You should have "cgi.fix_pathinfo = 0;" in php.ini
           fastcgi_pass unix:/var/run/php5-fpm.sock;
           fastcgi_index index.php;
           include fastcgi_params;
    }


    location ~ /\.ht {
            deny all;
    }

}
EOF

apt-get install php5-fpm -y

ln -s /etc/nginx/sites-available/i-tee /etc/nginx/sites-enabled/

rm /etc/nginx/sites-enabled/default

service nginx restart
cp /usr/share/nginx/phpvirtualbox/config.php-example \
/usr/share/nginx/phpvirtualbox/config.php

vim /usr/share/nginx/phpvirtualbox/config.php

su - vbox -c'VBoxManage setproperty vrdeauthlibrary "VBoxAuthSimple"'

apt-get install ruby ruby-dev git-core curl zlib1g-dev -y
apt-get install libssl-dev libreadline-dev -y
apt-get install libyaml-dev libsqlite3-dev sqlite3 libxml2-dev -y
apt-get install libxslt1-dev libcurl4-openssl-dev -y
ruby -v
gem -v
mkdir -p /var/www/railsapps/
mkdir -p /var/labs/run/
mkdir /var/labs/isos/
chown vbox.www-data /var/labs/run/
chmod g+w /var/labs/run/
chmod g+s /var/labs/run/
cd /var/www/railsapps
git clone git://github.com/magavdraakon/i-tee.git
cd i-tee
apt-get install libmysqlclient-dev mysql-server -y



if [[ -r /var/www/railsapps/i-tee/config/database.yml ]]
then
    echo "Database already configured"
    echo "If you want to reset database then delete file /var/www/railsapps/i-tee/config/database.yml"
else

echo "Give mysql root password"
read MYSQLPWD

RANDOMPASSWORD=$(makepasswd --chars=14)

mysql -uroot -p$MYSQLPWD << EOF
create database itee_production character set utf8;
create user 'itee'@'localhost' identified by '$RANDOMPASSWORD';
grant all privileges on itee_production.* to 'itee'@'localhost';
quit;
EOF

cat > /var/www/railsapps/i-tee/config/database.yml << EOF
production:
  adapter: mysql
  database: itee_production
  username: itee
  password: $RANDOMPASSWORD

# SQLite version 3.x
#   gem install sqlite3-ruby (not necessary on OS X Leopard)
development:
  adapter: sqlite3
  database: db/development.sqlite3
  pool: 5
  timeout: 5000

# Warning: The database defined as "test" will be erased and
# re-generated from your development database when you run "rake".
# Do not set this db to the same as development or production.
test:
  adapter: sqlite3
  database: db/test.sqlite3
  pool: 5
  timeout: 5000

EOF

fi

cp /usr/share/nginx/phpvirtualbox/config.php-example \
/usr/share/nginx/phpvirtualbox/config.php

#TODO change vbox password in config.php sed with vbox autogenerated password

su - vbox -c'VBoxManage setproperty vrdeauthlibrary "VBoxAuthSimple"'

./gen_config.sh

echo "CREATE PROPER LDAP CONFIG"

sudo apt-get install bundler -y
cd /var/www/railsapps/i-tee/
sudo bundle install
sudo rake db:migrate RAILS_ENV="production"
sudo rake db:seed RAILS_ENV="production"
sudo gem install passenger
sudo apt-get install libcurl4-openssl-dev -y
sudo apt-get install libssl-dev -y
sudo apt-get install apache2 -y

sudo apt-get install apache2-prefork-dev -y
sudo apt-get install libapr1-dev -y
sudo apt-get install libaprutil1-dev -y

sudo passenger-install-apache2-module

if [ -r /etc/apache2/sites-available/itee.conf ]
then
    echo "Configuration already exists"
    echo "Will not overwrite web config"
    echo "if you want overwrite then remove file /etc/apache2/sites-available/itee.conf"
else
sudo cat > /etc/apache2/sites-available/itee.conf << EOF
   <VirtualHost *:80>
      ServerName $(hostname -f)
      # !!! Be sure to point DocumentRoot to 'public'!
      DocumentRoot /var/www/railsapps/i-tee/public
      RewriteEngine On
      RewriteCond %{HTTPS} off
      RewriteRule (.*) https://%{HTTP_HOST}%{REQUEST_URI}
      ErrorLog /var/log/apache2/error-itee.log
      LogLevel warn
      CustomLog /var/log/apache2/access-itee.log combined
      <Directory /var/www/railsapps/i-tee/public>
         # This relaxes Apache security settings.
         AllowOverride all
         # MultiViews must be turned off.
         Options -MultiViews
         # Uncomment this if you're on Apache >= 2.4:
         Require all granted
      </Directory>
   </VirtualHost>


  <VirtualHost *:443>
    ServerName $(hostname -f)
    DocumentRoot /var/www/railsapps/i-tee/public
    ErrorLog /var/log/apache2/error-itee.log
    LogLevel warn
    CustomLog /var/log/apache2/access-itee.log combined
    SSLEngine on
    SSLProtocol All -SSLv2 -SSLv3
    SSLCertificateFile /etc/ssl/certs/YOUR-FQDN.pem
    SSLCertificateKeyFile /etc/ssl/private/YOUR-FQDN.key
    SSLOptions +StdEnvVars
  </VirtualHost>
EOF

fi

sudo a2enmod ssl rewrite headers
sudo a2ensite itee
sudo a2dissite 000-default.conf
sudo service apache2 restart

sudo adduser www-data vboxusers

sudo chown www-data:www-data /var/www -R
sudo chown vbox.www-data /var/labs/run/

sudo cat >/etc/sudoers.d/itee<<END
www-data ALL=(vbox) NOPASSWD: /var/www/railsapps/i-tee/utils/start_machine.sh
www-data ALL=(vbox) NOPASSWD: /var/www/railsapps/i-tee/utils/stop_machine.sh
www-data ALL=(vbox) NOPASSWD: /var/www/railsapps/i-tee/utils/resume_machine.sh
www-data ALL=(vbox) NOPASSWD: /var/www/railsapps/i-tee/utils/pause_machine.sh
www-data ALL=(vbox) NOPASSWD: /var/www/railsapps/i-tee/utils/delete_machine.sh
www-data ALL=(vbox) NOPASSWD: /usr/bin/VBoxManage
END

#TODO    LoadModule passenger_module /var/lib/gems/1.9.1/gems/passenger-5.0.16/buildout/apache2/mod_passenger.so
#   <IfModule mod_passenger.c>
#     PassengerRoot /var/lib/gems/1.9.1/gems/passenger-5.0.16
#     PassengerDefaultRuby /usr/bin/ruby1.9.1
#   </IfModule>

sudo chmod 0440 /etc/sudoers.d/itee
sudo mkdir /var/www/.config/
sudo chown vbox:vbox /var/www/.config/

sudo cat >>~/.bash_aliases<<END
alias deploy='/var/www/railsapps/i-tee/utils/deploy.sh'
alias restart='touch /var/www/railsapps/i-tee/tmp/restart.txt'
END

sudo mkdir /var/www/railsapps/i-tee/tmp
sudo chown www-data:www-data /var/www/railsapps/i-tee/tmp/

su - vbox -c'VBoxManage setproperty vrdeauthlibrary "VBoxAuthSimple"'
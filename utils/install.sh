#!/usr/bin/env bash
# Author Margus Ernits
# License MIT


#TODO detect OS version

sudo apt-get update

sudo apt-get dist-upgrade

sudo apt-get install linux-headers-$(uname -r) build-essential dkms -y

sudo apt-get install unzip git htop -y


#Add virtualbox apt source to software sources list:

echo "deb http://download.virtualbox.org/virtualbox/debian trusty contrib" \
 > /etc/apt/sources.list.d/virtualbox.list


#Download and import Oracle VirtualBox public key:

wget -q http://download.virtualbox.org/virtualbox/debian/oracle_vbox.asc \
 -O- | sudo apt-key add -


apt-get update


apt-get install virtualbox-5.0
VER=$(apt-cache policy virtualbox-5.0 |grep Installed:| cut -f2 -d: |cut -f1 -d-|cut -f2 -d' ')
SUBVER=$(apt-cache policy virtualbox-5.0 |grep Installed:| cut -f2 -d: |cut -f1 -d~|cut -f2 -d' ')

echo $VER
echo $SUBVER

wget http://download.virtualbox.org/virtualbox/${VER}/Oracle_VM_VirtualBox_Extension_Pack-${SUBVER}.vbox-extpack
VBoxManage extpack install Oracle_VM_VirtualBox_Extension_Pack-${SUBVER}.vbox-extpack


VBoxManage list extpacks

adduser vbox
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


PHPWIRTUALBOX=5.0-2.zip

wget https://github.com/imoore76/phpvirtualbox/archive/$PHPWIRTUALBOX -O $PHPWIRTUALBOX

unzip $PHPWIRTUALBOX

cp -a /root/$PHPWIRTUALBOX /usr/share/nginx/

ln -s /usr/share/nginx/$PHPWIRTUALBOX /usr/share/nginx/phpvirtualbox

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
chown vbox.www-data /var/labs/run/
chmod g+w /var/labs/run/
chmod g+s /var/labs/run/
cd /var/www/railsapps
git clone git://github.com/magavdraakon/i-tee.git
cd i-tee
apt-get install libmysqlclient-dev mysql-server



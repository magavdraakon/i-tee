#!/bin/sh

#
# i-tee installation script designed for clean
# Ubuntu 16.04 LTS (Xenial) environments.
# Expects Ruby toolset and relevant files to
# exist in filesystem.
#
# Relevant non-standard files and directories
#   /etc/apache2/sites-available/i-tee.conf
#   /etc/apache2/sites-available/phpvirtualbox.conf
#   /etc/apt/sources.list.d/virtualbox.list
#   /etc/default/virtualbox
#   /etc/sudoers.d/i-tee
#   /etc/vbox/auto.cfg
#   /var/labs/isos/
#   /var/labs/run/
#   /var/labs/.config/
#
# Example directory structure is available at
# https://github.com/keijokapp/i-tee.docker/tree/master/fs
#


set -e
trap "exit 1" INT

apt-get update

apt-get install -y curl

curl http://download.virtualbox.org/virtualbox/debian/oracle_vbox_2016.asc | apt-key add -
apt-get update


apt-get install -y sudo apache2 libapache2-mod-php7.0 php-soap php-xml virtualbox-5.0


a2enmod rewrite headers
rm /etc/apache2/sites-enabled/*
echo "Listen 80" > /etc/apache2/ports.conf
echo "Listen 4433" >> /etc/apache2/ports.conf


### Setup users and persissions

VBOX_PASSWD=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c32)
useradd -d /var/labs -G vboxusers vbox
echo "vbox:$VBOX_PASSWD" | chpasswd
adduser www-data vboxusers
chown :vboxusers /etc/vbox
chown www-data:www-data /var/www -R
chown vbox:vbox /var/labs/ -R
chown vbox:www-data /var/labs/run
chmod g+sw /var/labs
chmod 0440 /etc/sudoers.d/i-tee


### Install Virtualbox

# Configure Virtualbox autostart

su - vbox -c "VBoxManage setproperty autostartdbpath /etc/vbox"
su - vbox -c "vboxmanage setproperty vrdeauthlibrary VBoxAuthSimple"

# Install Virtualbox Extension Pack

VBoxManage extpack uninstall "Oracle VM VirtualBox Extension Pack" 2>/dev/null
su - vbox -c "vboxmanage extpack uninstall \"Oracle VM VirtualBox Extension Pack\" 2>/dev/null"

VERSION=$(apt-cache policy virtualbox-5.0 |grep Installed:| cut -f2 -d: |cut -f1 -d-|cut -f2 -d' ')
SUBVERSION=$(apt-cache policy virtualbox-5.0 |grep Installed:| cut -f2 -d: |cut -f1 -d~|cut -f2 -d' ')

curl "http://download.virtualbox.org/virtualbox/$VERSION/Oracle_VM_VirtualBox_Extension_Pack-$SUBVERSION.vbox-extpack" > \
	"/tmp/Oracle_VM_VirtualBox_Extension_Pack-$SUBVERSION.vbox-extpack"
VBoxManage extpack install "/tmp/Oracle_VM_VirtualBox_Extension_Pack-$SUBVERSION.vbox-extpack"


### Install phpvirtualbox

sed "s@var \$password = 'pass';@var \$password = '$VBOX_PASSWD';@" \
	/var/www/phpvirtualbox/config.php-example > /var/www/phpvirtualbox/config.php

a2ensite phpvirtualbox


### Install i-tee

if [ -x /usr/local/bin/checkout.sh ]
then

	# Development mode

	apt-get install -y git

fi


# FIXME: ensure that all these packages are really needed
apt-get install -y apache2-dev libapr1-dev libaprutil1-dev libcurl4-openssl-dev \
                   libgmp-dev libmysqlclient-dev libreadline-dev libsqlite3-dev \
                   libssl-dev libxml2-dev libxslt1-dev libyaml-dev sqlite3 zlib1g-dev

# Deep Magic below

#./gen_config.sh

cp /var/www/i-tee/config/environments/production_sample.rb \
	/var/www/i-tee/config/environments/production.rb

gem install bundler passenger

cd /var/www/i-tee
bundle install

passenger-install-apache2-module --snippet > /etc/apache2/mods-available/passenger.load
a2enmod passenger

passenger-install-apache2-module -a --languages ruby
a2ensite i-tee


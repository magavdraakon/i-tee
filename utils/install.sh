#!/bin/sh

#
# i-tee installation script designed for clean
# Ubuntu 16.04 LTS (Xenial) and Debian Jessie
# environments. Expects Ruby toolset and relevant
# files to exist in filesystem.
#
# Relevant non-standard files and directories
#   /etc/apache2/sites-available/i-tee.conf
#   /etc/apache2/sites-available/phpvirtualbox.conf
#   /etc/apt/sources.list.d/virtualbox.list
#   /etc/sudoers.d/i-tee
#   /var/labs/run/
#   /var/labs/.config/
#   /var/www/phpvirtualbox/
#   /var/www/i-tee/
#
# Example directory structure is available at
# https://github.com/keijokapp/i-tee.docker/tree/master/fs
#


set -e
trap "exit 1" INT

apt-get update

apt-get install -y --no-install-recommends curl

curl http://download.virtualbox.org/virtualbox/debian/oracle_vbox_2016.asc | apt-key add -
apt-get update


apt-get install -y --no-install-recommends sudo apache2 libapache2-mod-php5 php-soap \
                                           php-xml-parser virtualbox-5.0  libyaml-0-2 \
                                           libgmp-dev libmysqlclient-dev libsqlite3-dev

gem install bundler


### Setup users and persissions

VBOX_PASSWD=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c32)
useradd -d /var/labs -G vboxusers vbox
echo "vbox:$VBOX_PASSWD" | chpasswd
adduser www-data vboxusers
chown :vboxusers /etc/vbox
chown www-data:www-data /var/www -R
chown vbox:vbox /var/labs/ -R
chmod g+sw /var/labs
chmod 0440 /etc/sudoers.d/i-tee


### Install Virtualbox

# Configure Virtualbox autostart

su - vbox -c "vboxmanage setproperty vrdeauthlibrary VBoxAuthSimple"

# Install Virtualbox Extension Pack

VBoxManage extpack uninstall "Oracle VM VirtualBox Extension Pack" 2>/dev/null
su - vbox -c "vboxmanage extpack uninstall \"Oracle VM VirtualBox Extension Pack\" 2>/dev/null"

VERSION=$(apt-cache policy virtualbox-5.0 |grep Installed:| cut -f2 -d: |cut -f1 -d-|cut -f2 -d' ')
SUBVERSION=$(apt-cache policy virtualbox-5.0 |grep Installed:| cut -f2 -d: |cut -f1 -d~|cut -f2 -d' ')

curl "http://download.virtualbox.org/virtualbox/$VERSION/Oracle_VM_VirtualBox_Extension_Pack-$SUBVERSION.vbox-extpack" > \
	"/tmp/Oracle_VM_VirtualBox_Extension_Pack-$SUBVERSION.vbox-extpack"
VBoxManage extpack install "/tmp/Oracle_VM_VirtualBox_Extension_Pack-$SUBVERSION.vbox-extpack"

rm /tmp/.vbox-*-ipc -r


### Install phpvirtualbox

sed "s@var \$password = 'pass';@var \$password = '$VBOX_PASSWD';@" \
	/var/www/phpvirtualbox/config.php-example > /var/www/phpvirtualbox/config.php

echo > /etc/apache2/ports.conf
rm /etc/apache2/sites-enabled/*
a2ensite phpvirtualbox


### Install i-tee

cp /var/www/i-tee/config/environments/production_sample.rb \
	 /var/www/i-tee/config/environments/production.rb

cd /var/www/i-tee

bundle install



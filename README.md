# About i-tee
i-tee is a distance laboratory system, that is based on ruby on rails and uses VirtualBox headless virtualization.

i-tee is developed by the Estonian IT College.


# Preparing for installation of i-tee

Before installing i-tee system the Ubuntu server with VirtualBox headless is needed.


* Install Ubuntu Server 14.04 LTS 64bit with separate /var directory (enough room for virtual machines)
* Choose btrfs filesystem for /var for virtual machines
* Configure network

Do system upgrade

	sudo apt-get update

	sudo apt-get dist-upgrade

	sudo apt-get install linux-headers-$(uname -r) build-essential dkms

	sudo apt-get install unzip


Install GIT: 

	sudo apt-get install git


Install optional packages:

	sudo apt-get install htop

# Installing virtualization layer

For virtualization layer the VirtualBox headless mode is used with phpVirtualBox web interface.


## Installing VirtualBox headless

VirtualBox headless installation guide is based on [HowtoForge - Linux Tutorials](http://www.howtoforge.com) article:
[VBoxHeadless - Running Virtual Machines With VirtualBox 4.3 On A Headless Ubuntu 14.04 LTS Server - Author: Falko Timme, updated by Srijan Kishore](http://www.howtoforge.com/vboxheadless-running-virtual-machines-with-virtualbox-4.3-on-a-headless-ubuntu-14.04-lts-server)

All commands followed must be entered as a root user. To get interactive root shell:

	sudo -i
	
Add virtualbox apt source to software sources list:

	echo "deb http://download.virtualbox.org/virtualbox/debian trusty contrib" \
	 > /etc/apt/sources.list.d/virtualbox.list

Download and import Oracle VirtualBox public key:

	wget -q http://download.virtualbox.org/virtualbox/debian/oracle_vbox.asc \
	 -O- | sudo apt-key add -

Upgrade local repository cache:
	
	apt-get update

Install VirtualBox 4.3 package:

	apt-get install virtualbox-4.3

If everything is successful then module list should contain vboxdrv module. Test it using lsmod:
	
	lsmod |grep vboxdrv

The result should look like:

vboxdrv               409815  3 vboxnetadp,vboxnetflt,vboxpci


Download and install VirtualBox Extension Pack that corresponds to your version of VirtualBox:

	wget http://download.virtualbox.org/virtualbox/4.3.16/Oracle_VM_VirtualBox_Extension_Pack-4.3.16-95972.vbox-extpack

Install the extension pack using vboxmanage:

	VBoxManage extpack install Oracle_VM_VirtualBox_Extension_Pack-4.3.16-95972.vbox-extpack

List extension packs using vboxmanage:

	VBoxManage list extpacks

The result should contain
	
	Oracle VM VirtualBox Extension Pack

Create user ***vbox*** for virtualbox with strong password:

	adduser vbox

Add user ***vbox*** to group ***vboxusers***:

	adduser vbox vboxusers

Change ***vbox*** user home directory to ***/var/labs*** and move dotfiles into it:

	usermod -d /var/labs -m vbox


### Creating autostart files and configuring vbox user
To create complete virtual laboratory environment you need DNS server for fake zones, DHCP server for lab VMs and probably firewall for filtering.
For some VMs such as nameserver, DHCP server, Fitewall etc the autostart is needed.

```
cat >> /etc/default/virtualbox << EOF
VBOXWEB_USER=vbox
VBOXAUTOSTART_DB=/etc/vbox
VBOXAUTOSTART_CONFIG=/etc/vbox/auto.cfg
EOF
```

```
cat >> /etc/vbox/auto.cfg << EOF
default_policy = deny
vbox = {
        allow = true
        startup_delay = 10
}
EOF
```



## Installing phpVirtualBox 

Ensure that user ***vbox*** is configured as ***VBOXWEB_USER***

	grep vbox /etc/default/virtualbox

Enable ***vboxweb service*** autostart:

	update-rc.d vboxweb-service defaults
	service vboxweb-service start

### Installing nginx web server with php

Install ***nginx*** web server:

	sudo apt-get install nginx

Create new virtualhost ***i-tee***

We setup separate virtualhost for managing interface (phpVirtualBox) and the lab web application (ports: 4433 for phpVirtualbox and 443 for i-tee web app)

Make sure that you have FQDN for your website.
Generate SSL key for phpVirtualBox virtualhost

	ssh-keygen -f /etc/ssl/private/YOUR-FQDN.key

Press enter twice if you do not want passpharse for key.


Generate certificate request


	openssl req -new -key /etc/ssl/private/YOUR-FQDN.key \
		 -out /root/YOUR-FQDN.req


Country Name (2 letter code) [AU]: < -- Enter Country Code (example EE)
State or Province Name (full name) [Some-State]: < -- Enter your state name (example Harjumaa)

Locality Name (eg, city) []: < -- Enter City Name (example Tallinn)
Organization Name (eg, company) [Internet Widgits Pty Ltd]: < -- Enter Organization name (example Estonian IT College)
Organizational Unit Name (eg, section) []: < -- Hit enter
Common Name (e.g. server FQDN or YOUR name) []: < -- YOUR-FQDN (example i-tee.itcollege.ee)
Email Address []:< -- Hit enter
A challenge password []:< -- Hit enter
An optional company name []:< -- Hit enter

To check certificate data:
	
	openssl req -in /root/YOUR-FQDN.req -text -noout

Use CA to sign certificate or self signed cert in case of test environment only


NB for testing only 

	openssl x509 -req -days 3650 -in /root/YOUR-FQDN.req -signkey /etc/ssl/private/YOUR-FQDN.key -out  /etc/ssl/certs/YOUR-FQDN.pem

After signing sertificate please copy signed cert into /etc/ssl/certs/
For example open certificate file /etc/ssl/certs/YOUR-FQDN.pem and copy signed cert into this file.

To check signed certificate data:

	openssl x509 -in /etc/ssl/certs/YOUR-FQDN.pem -text -noout


Download latest version of phpVirtualBox http://sourceforge.net/projects/phpvirtualbox/files/?source=navbar
VirtualBox and phpVirtualBox versions must match. For example, for VirtualBox-4.3 series you need phpvirtualbox-4.3-x.zip:

	
	wget http://sourceforge.net/projects/phpvirtualbox/files/phpvirtualbox-4.3-1.zip/download \
	 -O phpvirtualbox-4.3-1.zip

	unzip phpvirtualbox-4.3-1.zip


Create new virtualhost for phpVirtualBox

	cat > /etc/nginx/sites-available/i-tee << EOF
	# HTTPS server
	#
	server {
		listen 4433;
	#       server_name localhost;
	#
	#       root html;
	#       index index.html index.htm;
	#
		root /usr/share/nginx/www/phpvirtualbox;
		index index.php index.html index.htm;

		ssl on;
		ssl_certificate /etc/ssl/certs/YOUR-FQDN.pem;
		ssl_certificate_key /etc/ssl/private/YOUR-FQDN.key;
	#
	# TODO TO Test
	#      ssl_session_timeout 5m;
	#
	#      ssl_protocols SSLv3 TLSv1 TLSv1.1 TLSv1.2;
	#      ssl_ciphers "HIGH:!aNULL:!MD5 or HIGH:!aNULL:!MD5:!3DES";
	#      ssl_prefer_server_ciphers on;
		ssl_session_timeout 5m;
	#
		ssl_protocols SSLv3 TLSv1;
		ssl_ciphers ALL:!ADH:!EXPORT56:RC4+RSA:+HIGH:+MEDIUM:+LOW:+SSLv3:+EXP;
		ssl_prefer_server_ciphers on;
	#
		location / {
		        try_files $uri $uri/ /index.html;
		}
		# pass the PHP scripts to FastCGI server listening on 127.0.0.1:9000
		#
	#        location ~ \.php$ {
	#                try_files $uri =404;
	#                fastcgi_split_path_info ^(.+\.php)(/.+)$;
	#                fastcgi_pass 127.0.0.1:9000;
	#                fastcgi_index index.php;
	#                include fastcgi_params;
	#        }
		# pass the PHP scripts to FastCGI server listening on 127.0.0.1:9000
		#
		location ~ \.php$ {
		       fastcgi_split_path_info ^(.+\.php)(/.+)$;
		       # NOTE: You should have "cgi.fix_pathinfo = 0;" in php.ini

		       # With php5-cgi alone:
		       #fastcgi_pass 127.0.0.1:9000;
		       # With php5-fpm:
		       fastcgi_pass unix:/var/run/php5-fpm.sock;
		       fastcgi_index index.php;
		       include fastcgi_params;
		}


		location ~ /\.ht {
		        deny all;
		}

	}
	EOF

uurida - http://www.iodigitalsec.com/nginx-ssl-php5-fpm-on-debian-wheezy/






# Application Config
Configuration files are needed as following with sample files included:

- config/environments/development.rb
- config/environments/production.rb
- config/environments/test.rb
- config/ldap.yml
- config/database.yml


# Installation

make yourself the root user

	sudo -i

Check the version of ruby and rails installed:

	ruby -v
	ruby 1.8.7 (2010-01-10 patchlevel 249) [x86_64-linux]

if you dont have ruby installed:

	apt-get install ruby

download the newest RubyGems (http://rubygems.org)

    wget http://production.cf.rubygems.org/rubygems/rubygems-1.4.1.tgz
    tar zxf rubygems-1.4.1.tgz

to install RubyGems run setup.rb in the rubygems-1.4.1/ folder

    cd rubygems-1.4.1/
    ruby setup.rb
    
make the installed RubyGem as a default

    update-alternatives --install /usr/bin/gem gem /usr/bin/gem1.8 1


check the version:

	rails -v
	Rails 3.0.4

if you dont have rails installed:

	gem install rails -v=3.0.4

Have git installed:

	apt-get install git-core

install uuid

	apt-get install uuid

install Libvirt and KVM

	apt-get install libvirtd kvm



## installing the distance laboratory system

Create the railsapps directory

	mkdir /var/www/railsapps/

Download the code from GitHub to the newly created folder

	cd /var/www/railsapps
	git clone git://github.com/magavdraakon/i-tee.git

Go to the project folder

	cd i-tee

Create config files from the sample files

Changing the database config

	cp config/database_sample.yml config/database.yml 

For the database use mysql server.

	apt-get install libmysqlclient-dev mysql-server

run the mysql client under root

	mysql -p

Creating the user for the database:

	create database itee_production character set utf8;
	create user 'itee'@'localhost' identified by 's0mestrongpassw0rd';
	grant all privileges on itee_production.* to 'itee'@'localhost';

Change info in the database.yml file

	production:
		adapter: mysql
		database: itee_production
		username: itee
		password: s0mestrongpassw0rd

Getting the production config

	cp config/environments/production_sample.rb config/environments/production.rb 

Ensure that emulate_virtualization is set to false

	config.emulate_virtualization = false
	config.emulate_ldap = false

Enter admin usernames

	#Administrator usernames
	config.admins = ['admin1','admin2','admin3','etc']

Create the LDAP config

	cp config/ldap_sample.yml config/ldap.yml 

And change the info according to your own LDAP server settings

	production:
		host: yourhost
		port: 636
		attribute: cn
		base: ou=people,dc=test,dc=com
		admin_user: cn=admin,dc=test,dc=com
		admin_password: admin_password
		ssl: true

install the sqlite development packages

	apt-get install libsqlite3-dev 

Install gems

	bundle install

Now migrate the database

	rake db:migrate RAILS_ENV="production"

Add default data to the tables

	rake db:seed RAILS_ENV="production" 

NB! this fills the mac address table with ip-s from 192.168.13.102 to 192.168.13.220,
you can change the seed to match your settings!


## installing passenger

install passenger for hosting Rails applications 

	gem install passenger

Install the required software:

Curl development headers with SSL support

	apt-get install libcurl4-openssl-dev

OpenSSL development headers

	apt-get install libssl-dev
  
Apache 2 web server

	apt-get install apache2

Apache 2 development headers

	apt-get install apache2-prefork-dev

Apache Portable Runtime (APR) development headers

	apt-get install libapr1-dev

Apache Portable Runtime Utility (APU) development headers

	apt-get install libaprutil1-dev

And run the installer

	passenger-install-apache2-module

Create new configuration files to enable passenger

	/etc/apache2/mods-available/passenger.load
	/etc/apache2/mods-available/passenger.conf

NB! the following lines are given to you during passenger installation

insert the similar line into the .load file

	LoadModule passenger_module /usr/lib/ruby/gems/1.8/gems/passenger-<version>/ext/apache2/mod_passenger.so

insert the similar lines into the .conf file

	PassengerRoot /usr/lib/ruby/gems/1.8/gems/passenger-<version>
	PassengerRuby /usr/bin/ruby1.8

execute these commands to enable passenger and restart the apache server

	a2enmod passenger
	/etc/init.d/apache2 restart

Create a file 

	/etc/apache2/sites-available/itee

And insert the following lines

	<VirtualHost *:80>
		ServerName  <server (ie: project.itcollege.ee)>
		DocumentRoot /var/www/railsapps/i-tee/public
		<Directory /var/www/railsapps/i-tee/public>
			AllowOverride all
			Options -MultiViews
		</Directory>
	</VirtualHost>

Disable the default site

	a2dissite default

and enable the new site

	a2ensite itee

reload the web servers configuration files

	/etc/init.d/apache2 reload


## configuring Apache to use HTTPS

generate a private key

	openssl genrsa -des3 -out project.key 4096

generate a public key

	openssl rsa -in project.key -out project.key.insecure

move the private key to the Apache folder 

	cp project.key.insecure /etc/apache2/project.key

go to the Apache folder

	cd /etc/apache2

remove the writing and reading permission of the private key from other users

	chmod go-rwx project.key

ask for a certificate

	openssl req -new -key project.key -out project.csr

copy the signed certificate request into the /etc/apache2/project.pem file

change the file /etc/apache2/sites-available/itee to:

	NameVirtualHost *:80
	<VirtualHost *:80>
		ServerName <server (ie: project.itcollege.ee)>
		DocumentRoot /var/www/railsapps/i-tee/public
		RewriteEngine On
		RewriteCond %{HTTPS} off
		RewriteRule (.*) https://%{HTTP_HOST}%{REQUEST_URI}
		ErrorLog /var/log/apache2/error-itee.log
			LogLevel warn
		CustomLog /var/log/apache2/access-itee.log combined
	</VirtualHost>
	
	NameVirtualHost *:443

	<VirtualHost *:443>
		ServerName <server (ie: project.itcollege.ee)>
		DocumentRoot /var/www/railsapps/i-tee/public
		ErrorLog /var/log/apache2/error-itee.log
			LogLevel warn
		CustomLog /var/log/apache2/access-itee.log combined
		SSLEngine on
		SSLCertificateFile /etc/apache2/project.pem
		SSLCertificateKeyFile /etc/apache2/project.key
		SSLOptions +StdEnvVars
	</VirtualHost>



## install a DHCP server (ie. on a virtual machine)
make yourself the root user

	sudo -i

update the package list

	apt-get update

install the DHCP server

	apt-get install dhcp3-server

make a folder for backups if you dont have one

	mkdir /var/backups

make a back-up of the DHCP configuration

	cp -r /etc/default/dhcp3-server /var/backups
	cp /etc/dhcp3/dhcpd.conf /var/backups

change the DHCP configuration

	nano /etc/default/dhcp3-server

	INTERFACES="eth0”

change the file /etc/dhcp3/dhcpd.conf 

	nano /etc/dhcp3/dhcpd.conf

add:

	subnet 192.168.13.0 netmask 255.255.255.0 {
		range 192.168.13.101 192.168.13.220;
		default-lease-time 600;
		max-lease-time 7200;
		option routers 192.168.13.254;
		host virtlab101 {
			hardware ethernet 52:54:00:e8:8b:a3;
			fixed-address 192.168.13.101;
		}
	}

for each planned MAC address add a host block:

	host <name> {
		hardware ethernet <MAC>;
		fixed-address <IP>;
	}

NB! configure the domain-name

	option domain-name "<domain name>";
	option domain-name-servers 172.16.0.175, 172.16.0.165;

restart the DHCP server

	/etc/init.d/dhcp3-server restart



## configuring a network bridge for the Livbirt virtual machines

alter the /etc/network/interfaces file that contains:

	auto eth0
	iface eth0 inet static
		address 192.168.2.4
		netmask 255.255.255.0
		network 192.168.2.0
		broadcast 192.168.2.255
		gateway 192.168.2.2

and add (for the default 192.168.13.x network):
 
	auto br0
	iface br0 inet static
		address 192.168.13.13
		netmask 255.255.255.0
		network 192.168.13.0
		broadcast 192.168.13.255
		gateway 192.168.13.254

	dns-nameservers <ip aadress>
	dns-search <site.com>
	bridge_stp on
	bridge_ports eth0
	bridge_fd 9
	bridge_maxage 12

enable port forwarding using iptables

	pre-up /var/www/railsapps/i-tee/utils/port-forward.sh


activate the bridge

	ifup br0

add the following lines to the /etc/sysctl.conf file

	net.bridge.bridge-nf-call-ip6tables = 0
	net.bridge.bridge-nf-call-iptables = 0
	net.bridge.bridge-nf-call-arptables = 0
	net.ipv4.ip_forward=1

load the settings:

	sysctl -p /etc/sysctl.conf

control the results

	brctl show

	bridge name 	bridge id	 	        STP enabled 	interfaces
	br0 	      	8000.000e0cb30550 	 yes 	        eth0

if STP is enabled for br0, then the guest can use the hosts physical device and has full LAN access


In order to let your virtual machines use this bridge, their configuration file should include:

	<interface type='bridge'>
		<source bridge='br0'/>
		<mac address='<mac address>'/>
	</interface>


To see the site go to

	http://localhost


please refer to the system guide (/system) page to enable working with virtual machines from the user interface

#TODO
VirualBox permissions
User vbox (group vboxusers)

	www-data ALL=(vbox) NOPASSWD: /var/www/railsapps/i-tee/utils/start_machine.sh
Integration with btrfs deduplication tool: https://github.com/g2p/bedup

http://www.vionblog.com/virtualbox-4-3-autostart-debian-wheezy/


https://gist.github.com/mikedevita/7461832

##For developers

For documentation:

	wget http://github.github.com/github-flavored-markdown/shared/css/documentation.css

	gimli -f ./README.md -s documentation.css

#Guest setup
-Virtualbox additions

# Authors
Tiia Tänav

Margus Ernits

Carolyn Fischer (retired)

Aivar Guitar (retired)

Madis Toom (retired)


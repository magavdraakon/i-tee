#!/bin/bash

set -e

export LC_ALL=C

#Colors settings
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m'

mkdir -p /etc/i-tee
LOGFILE=/etc/i-tee/install.log

echo -e "\n${YELLOW}" 2>&1 | tee -a $LOGFILE
echo -e "#####################################################" 2>&1 | tee -a $LOGFILE
echo -e "##############-I-TEE INSTALLATION SCRIPT-############" 2>&1 | tee -a $LOGFILE
echo -e "#####################################################" 2>&1 | tee -a $LOGFILE
echo -e "${NC}" 2>&1 | tee -a $LOGFILE

echo -e "\n$(date '+%Y-%m-%d %H:%M:%S') - ${YELLOW}Starting i-tee installation script from $(pwd)${NC}" 2>&1 | tee -a $LOGFILE

if [ $UID -ne 0 ]
then
    echo -e "\n$(date '+%Y-%m-%d %H:%M:%S') - ${RED}Error: Wrong User! Please start ${BASH_SOURCE[0]} with root! Exiting...${NC}" 2>&1 | tee -a $LOGFILE
	exit 1
fi

cd "$( dirname "${BASH_SOURCE[0]}" )"
### Disk tuning

echo 1 > /proc/sys/vm/dirty_background_ratio
echo 80 > /proc/sys/vm/dirty_ratio
echo -e "\n$(date '+%Y-%m-%d %H:%M:%S') - ${YELLOW}Disk Tuning Done ${NC}" 2>&1 | tee -a $LOGFILE
### Download necessary tools

echo -e "\n$(date '+%Y-%m-%d %H:%M:%S') - ${YELLOW}Downloading json-util and installing required packages ${NC}" 2>&1 | tee -a $LOGFILE

curl -L https://github.com/keijokapp/json-util/releases/download/1.0/json-util -o /usr/local/bin/json-util
chmod +x /usr/local/bin/json-util

apt-get update > /dev/null
apt-get install --no-install-recommends -y rsync curl ssh hostname ferm ssl-cert nginx apache2-utils pwgen nodejs npm linux-headers-generic 2>&1 | tee -a $LOGFILE

### Install static files
echo -e "\n$(date '+%Y-%m-%d %H:%M:%S') - ${YELLOW}Copying static files and services ${NC}" 2>&1 | tee -a $LOGFILE
set +e

cp ./etc/default/virtualbox /etc/default/virtualbox
cp ./etc/default/ferm /etc/default/ferm

cat > /etc/ferm/firewall.conf<<END
# Default default firewall customization file
@def \$OUTER_IF=($(ip route ls |grep default | awk '{print $5}'));
END

cp ./etc/ferm/ferm.conf /etc/ferm/ferm.conf
mkdir -p /usr/local/share/guacamole/
cp ./usr/local/share/guacamole/initdb.mysql.sql /usr/local/share/guacamole/initdb.mysql.sql
mkdir -p /usr/local/lib/systemd/system/
cp ./usr/local/lib/systemd/system/*.service /usr/local/lib/systemd/system/

cat > /usr/local/lib/systemd/system/i-tee.service <<EOL


[Unit]
Requires=docker.service
After=docker.service


[Install]
WantedBy=multi-user.target


[Service]
ExecStartPre=-/usr/bin/env docker rm -f i-tee
ExecStartPre=/bin/sh -c "docker create \\
	--add-host \"host.local:172.17.0.1\" \\
	--name i-tee \\
	--publish "172.17.0.1:8080:80" \\
	--env "VBOX_USER=vbox" \\
	--env "VBOX_HOST=172.17.0.1" \\
	--env "VBOX_PORT=22" \\
	--env "ITEE_SECRET_TOKEN=$(pwgen 128 1)" \\
	--volume /etc/i-tee/config.yaml:/etc/i-tee/config.yaml:ro \\
	--volume /etc/i-tee/id_rsa:/root/.ssh/id_rsa:ro \\
	--volume /etc/i-tee/known_hosts:/root/.ssh/known_hosts:ro \\
	--volume /var/labs/exports:/var/labs/exports \\
	--volume /var/labs/run:/var/labs/run \\
	-t \\
	rangeforce/i-tee:latest"
ExecStart=/usr/bin/env docker start -a i-tee
ExecStop=/usr/bin/env docker stop i-tee
SuccessExitStatus=143
Restart=always
RestartSec=3
EOL

mkdir -p /etc/vbox
cp ./etc/vbox/autostart.conf /etc/vbox/autostart.conf
mkdir -p /etc/nginx

mkdir -p /etc/nginx/sites-available
cp ./etc/nginx/sites-available/lab-proxy /etc/nginx/sites-available/lab-proxy
cp ./etc/nginx/sites-available/default /etc/nginx/sites-available/default
mkdir -p /etc/i-tee
mkdir -p /etc/systemd/system/docker.service.d
cp ./etc/systemd/system/docker.service.d/noiptables.conf /etc/systemd/system/docker.service.d/noiptables.conf
cp ./etc/sysctl.d/80-labs.conf /etc/sysctl.d/80-labs.conf
set -e

#rise sshd limits
echo -e "\n$(date '+%Y-%m-%d %H:%M:%S') - ${YELLOW}Rising sshd connection limits to 250 ${NC}" 2>&1 | tee -a $LOGFILE
echo "MaxSessions 250" >> /etc/ssh/sshd_config
echo "MaxStartups 250" >> /etc/ssh/sshd_config

### Create users, groups and respective directories
echo -e "\n$(date '+%Y-%m-%d %H:%M:%S') - ${YELLOW}Creating users, groups and respective directories ${NC}" 2>&1 | tee -a $LOGFILE
set +e
mkdir -p /var/labs
useradd -d /var/labs vbox 2>&1 | tee -a $LOGFILE
set -e

mkdir -p /var/labs/.config
chown vbox:vbox /var/labs -R
chmod u+s,g+s /var/labs -R

# Password is needed for phpVirtualbox
echo -e "\n$(date '+%Y-%m-%d %H:%M:%S') - ${YELLOW}Setting up virtualbox password ${NC}" 2>&1 | tee -a $LOGFILE
VBOX_PASSWORD=$(< /dev/urandom tr -dc _A-Za-z0-9 | head -c20)
echo "vbox:$VBOX_PASSWORD" | chpasswd

GUAC_TOKEN=$(pwgen 32 1)
echo "guacamole-proxy secret token: $GUAC_TOKEN" >> /root/i-tee-passwords.txt

### Install packages
echo -e "\n$(date '+%Y-%m-%d %H:%M:%S') - ${YELLOW}Installing Docker ${NC}" 2>&1 | tee -a $LOGFILE
install_docker() {
	apt-get remove docker docker-engine 2>&1 | tee -a $LOGFILE

	apt-get install -y --no-install-recommends \
		apt-transport-https \
    		curl \
    		software-properties-common 2>&1 | tee -a $LOGFILE
	curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

	add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" 2>&1 | tee -a $LOGFILE

	apt-get install -y --no-install-recommends \
		linux-image-extra-virtual 2>&1 | tee -a $LOGFILE


	apt-get update > /dev/null
	apt-get install -y docker-ce 2>&1 | tee -a $LOGFILE

}

install_virtualbox() {
    echo -e "\n$(date '+%Y-%m-%d %H:%M:%S') - ${YELLOW}Installing Virtualbox ${NC}" 2>&1 | tee -a $LOGFILE
	wget -q https://www.virtualbox.org/download/oracle_vbox_2016.asc -O- | sudo apt-key add -  
	wget -q https://www.virtualbox.org/download/oracle_vbox.asc -O- | sudo apt-key add -  
	sudo add-apt-repository "deb [arch=amd64] http://download.virtualbox.org/virtualbox/debian $(lsb_release -cs) contrib"
	apt update > /dev/null
	apt install --no-install-recommends -y virtualbox-5.2 gcc make  2>&1 | tee -a $LOGFILE
	apt dist-upgrade -y  2>&1 | tee -a $LOGFILE

	adduser vbox vboxusers  2>&1 | tee -a $LOGFILE

	VERSION=$(apt-cache policy virtualbox-5.2 | grep Installed: | cut -f2 -d: | cut -f1 -d- | cut -f2 -d' ')
	SUBVERSION=$(apt-cache policy virtualbox-5.2 | grep Installed: | cut -f2 -d: | cut -f1 -d~ | cut -f2 -d' ')

	curl "http://download.virtualbox.org/virtualbox/$VERSION/Oracle_VM_VirtualBox_Extension_Pack-$VERSION.vbox-extpack" > \
		"/tmp/Oracle_VM_VirtualBox_Extension_Pack-$VERSION.vbox-extpack"
	echo y | vboxmanage extpack install --replace "/tmp/Oracle_VM_VirtualBox_Extension_Pack-$VERSION.vbox-extpack"
	su - vbox -c "echo y | vboxmanage extpack install --replace '/tmp/Oracle_VM_VirtualBox_Extension_Pack-$SUBVERSION.vbox-extpack'" || true
	su - vbox -c "vboxmanage setproperty vrdeauthlibrary VBoxAuthSimple"

	apt-mark hold virtualbox-5.2  2>&1 | tee -a $LOGFILE
}
echo -e "\n$(date '+%Y-%m-%d %H:%M:%S') - ${YELLOW}Starting Docker and VirtualBox installation ${NC}" 2>&1 | tee -a $LOGFILE
install_docker
install_virtualbox

#Installing netdata
echo -e "\n$(date '+%Y-%m-%d %H:%M:%S') - ${YELLOW}Installing netdata ${NC}" 2>&1 | tee -a $LOGFILE
apt-get install netdata -y  2>&1 | tee -a $LOGFILE

### Cleanup
echo -e "\n$(date '+%Y-%m-%d %H:%M:%S') - ${YELLOW}Cleanup: Deleting old container if exists ${NC}" 2>&1 | tee -a $LOGFILE
echo "Deleting containers"
set +e
docker rm -f phpvirtualbox i-tee mysql guacamole guacd  > /dev/null
set -e

### Set up phpVirtualbox
echo -e "\n$(date '+%Y-%m-%d %H:%M:%S') - ${YELLOW}Setting up phpvirtualbox ${NC}" 2>&1 | tee -a $LOGFILE
mkdir -p /etc/phpvirtualbox 
echo "VBOX_PASSWORD=$VBOX_PASSWORD" > /etc/phpvirtualbox/environment

# Setup SSH between host and I-Tee container
echo -e "\n$(date '+%Y-%m-%d %H:%M:%S') - ${YELLOW}Setting up SSH connection between host and I-Tee container ${NC}" 2>&1 | tee -a $LOGFILE
docker run --rm --add-host host.local:172.17.0.1 --entrypoint ssh-keyscan iadknet/ssh-client-light 172.17.0.1 > /etc/i-tee/known_hosts
if [ ! -f /etc/i-tee/id_rsa ] || [ ! -f /var/labs/.ssh/authorized_keys ]
then
	ssh-keygen -t rsa -b 2048 -N "" -f /etc/i-tee/id_rsa
	mkdir -p /var/labs/.ssh
    mv /etc/i-tee/id_rsa.pub /var/labs/.ssh/authorized_keys
	chown vbox:vbox /var/labs/.ssh -R
fi
systemctl stop nginx.service
systemctl restart ferm.service
# Configure SSL keys used by proxy
#set +e
# These commands will not overwrite existing files
#ln -s /etc/ssl/certs/ssl-cert-snakeoil.pem /etc/ssl/private/i-tee.crt
#ln -s /etc/ssl/private/ssl-cert-snakeoil.key /etc/ssl/private/i-tee.key
#set -e

echo -e "\n$(date '+%Y-%m-%d %H:%M:%S') - ${YELLOW}Installing certbot and requesting LetsEncrypt certificate via certbot ${NC}" 2>&1 | tee -a $LOGFILE

apt-get install software-properties-common -y 2>&1 | tee -a $LOGFILE
add-apt-repository ppa:certbot/certbot -y 2>&1 | tee -a $LOGFILE
apt-get update > /dev/null
apt-get install python-certbot-nginx -y 2>&1 | tee -a $LOGFILE

certbot certonly --standalone --agree-tos --register-unsafely-without-email --preferred-challenges http -d $(hostname -f) 2>&1 | tee -a $LOGFILE

sed -i -e "s|/etc/ssl/certs/ssl-cert-snakeoil.pem|/etc/letsencrypt/live/$(hostname -f)/fullchain.pem|g" /etc/nginx/sites-available/default
sed -i -e "s|/etc/ssl/private/ssl-cert-snakeoil.key|/etc/letsencrypt/live/$(hostname -f)/privkey.pem|g" /etc/nginx/sites-available/default

echo -e "\n$(date '+%Y-%m-%d %H:%M:%S') - ${YELLOW}Adding crontab to automatically update the letsencrypt certificate ${NC}" 2>&1 | tee -a $LOGFILE

echo "45 2 * * 6 /usr/bin/certbot renew" >> /var/spool/cron/crontabs/root

# Create I-Tee configuration and install MySQL database

#if [ -d "/opt/mysql/data" ];
#    then
#        echo -e "\n$(date '+%Y-%m-%d %H:%M:%S') - ${YELLOW}Backing up current mysql data to /opt/mysql/data.backup ${NC}" 2>&1 | tee -a $LOGFILE
#        cp -r /opt/mysql/data /opt/mysql/data.backup_$(date +%Y-%m-%d)
#	echo -e "\n$(date '+%Y-%m-%d %H:%M:%S') - ${YELLOW}Removing old mysql data ${NC}" 2>&1 | tee -a $LOGFILE
#	rm -rf /opt/mysql/data
#fi

itee_magic() {
    echo -e "\n$(date '+%Y-%m-%d %H:%M:%S') - ${YELLOW}Starting with I-Tee installation ${NC}" 2>&1 | tee -a $LOGFILE
    
    ITEE_PASSWORD=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c20)
	GUACAMOLE_PASSWORD=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c20)
	MYSQL_PASSWORD=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c20)
    GUACADMINPASS=$(pwgen 32 1)
    GUACADMINUSER=$(pwgen 8 1)
	
	echo -e "\n$(date '+%Y-%m-%d %H:%M:%S') - ${YELLOW}Generated ITEE_PASSWORD = $ITEE_PASSWORD  ${NC}" 2>&1 | tee -a $LOGFILE
	echo -e "\n$(date '+%Y-%m-%d %H:%M:%S') - ${YELLOW}Generated GUACAMOLE_PASSWORD = $GUACAMOLE_PASSWORD  ${NC}" 2>&1 | tee -a $LOGFILE

	SQL=
	SQL="$SQL CREATE DATABASE IF NOT EXISTS itee;\n"
	SQL="$SQL CREATE DATABASE IF NOT EXISTS guacamole;\n"

	SQL="$SQL CREATE USER itee IDENTIFIED BY '$ITEE_PASSWORD';\n"
	SQL="$SQL GRANT ALL ON itee.* TO itee;\n"
	SQL="$SQL GRANT ALL ON guacamole.* TO itee;\n"

	SQL="$SQL CREATE USER guacamole IDENTIFIED BY '$GUACAMOLE_PASSWORD';\n"
	SQL="$SQL GRANT ALL ON guacamole.* TO guacamole;\n"
    echo -e "\n$(date '+%Y-%m-%d %H:%M:%S') - ${YELLOW}Initializing database ${NC}" 2>&1 | tee -a $LOGFILE
	
    echo -e "\n$(date '+%Y-%m-%d %H:%M:%S') - ${YELLOW}Removing old mysql data ${NC}" 2>&1 | tee -a $LOGFILE

	# Beware; printf interprets escape sequences. Using '%s' before second argument has
	# the opposite effect - replace some characters (i.e. newlines) with escape sequences.

	printf "$SQL" | docker run -i --rm --volume /opt/mysql/data:/var/lib/mysql --entrypoint mysqld mysql:5.7 --initialize --init-file=/dev/stdin
	MYSQL_ID=$(docker run -d --rm --volume /opt/mysql/data:/var/lib/mysql mysql:5.7)
	while true
	do
		if docker exec -i $MYSQL_ID mysql -uguacamole -p"$GUACAMOLE_PASSWORD" guacamole < /usr/local/share/guacamole/initdb.mysql.sql
		then
			break
		fi
		sleep 2
		echo -e "\n$(date '+%Y-%m-%d %H:%M:%S') - ${RED}Error: Database is not ready ${NC}" 2>&1 | tee -a $LOGFILE
	done

	docker stop $MYSQL_ID

    echo -e "\n$(date '+%Y-%m-%d %H:%M:%S') - ${YELLOW}Database initialized ${NC}" 2>&1 | tee -a $LOGFILE
    echo -e "\n$(date '+%Y-%m-%d %H:%M:%S') - ${YELLOW}Generating configuretion ${NC}" 2>&1 | tee -a $LOGFILE

	JSON=$(cat /etc/i-tee/config.yaml)
	FULL_HOSTNAME=$(hostname -f)
	DOMAIN_NAME=$(hostname -d)
	FULL_HOSTNAME_ENCODED=$(printf %s "$FULL_HOSTNAME" | json-util encode-string)
	DOMAIN_NAME_ENCODED=$(printf %s "$DOMAIN_NAME" | json-util encode-string)

	JSON_VALUE="{ \
		\"adapter\": \"mysql2\", \
		\"host\": \"172.17.0.1\", \
		\"username\": \"itee\", \
		\"password\": \"$ITEE_PASSWORD\", \
		\"database\": \"itee\" \
	}"
	JSON=$(printf "%s %s" "$JSON" "$JSON_VALUE" | json-util set database)

	JSON_VALUE="{ \
		\"adapter\": \"mysql2\", \
		\"host\": \"172.17.0.1\", \
		\"username\": \"guacamole\", \
		\"password\": \"$GUACAMOLE_PASSWORD\", \
		\"database\": \"guacamole\" \
	}"
	JSON=$(printf "%s %s" "$JSON" "$JSON_VALUE" | json-util set guacamole_database)
	
	JSON_VALUE="{ \
		\"ws_host\":\"wss://$FULL_HOSTNAME_ENCODED/gml/\", \
		\"cipher_password\":\"$GUAC_TOKEN\", \
		\"guacd_host\":\"host.local\", \
		\"username\":\"admin$GUACADMINUSER\", \
		\"password\":\"$GUACADMINPASS\" \
	}"
	JSON=$(printf "%s %s" "$JSON" "$JSON_VALUE" | json-util set guacamole2)
	if [ -z "$(printf %s \"$JSON\" | json-util get vbox)" ]
	then
		JSON_VALUE="{ \
			\"host\": \"http://172.18.0.1:12121\", \
			\"token\": \"REPLACE_WITH_MEMCACHE_TOKEN\" \
		}"
		JSON=$(printf "%s %s" "$JSON" "$JSON_VALUE" | json-util set vbox)
	fi
	if [ -z "$(printf %s \"$JSON\" | json-util get guacamole.url_prefix)" ]
	then
		JSON_VALUE="{ \
			\"url_prefix\": \"https://$FULL_HOSTNAME_ENCODED/guacamole\", \
			\"cookie_domain\": \"$DOMAIN_NAME_ENCODED\" \
		}"
		JSON=$(printf "%s %s" "$JSON" "$JSON_VALUE" | json-util set guacamole)
	fi

	if [ -z "$(printf %s \"$JSON\" | json-util get application_url)" ]
	then
		JSON_VALUE="\"https://$FULL_HOSTNAME_ENCODED\""
		JSON=$(printf "%s %s" "$JSON" "$JSON_VALUE" | json-util set application_url)
	fi

	JSON_VALUE='"172.17.0.1"'
	JSON=$(printf '%s %s' "$JSON" "$JSON_VALUE" | json-util set guacamole.rdp_host)

	if [ -z "$(printf %s \"$JSON\" | json-util get ldap)" ]
	then
		echo -e "\n$(date '+%Y-%m-%d %H:%M:%S') - ${RED}Warning: LDAP is not configured ${NC}" 2>&1 | tee -a $LOGFILE
	fi

	if [ -z "$(printf %s \"$JSON\" | json-util get skin)" ]
	then
		JSON_VALUE="\"EIK\""
		JSON=$(printf "%s %s" "$JSON $JSON_VALUE" | json-util set skin)
	fi

	if [ -z "$(printf %s \"$JSON\" | json-util get rdp_host)" ]
	then
		JSON_VALUE="\"$FULL_HOSTNAME_ENCODED\""
		JSON=$(printf "%s %s" "$JSON" "$JSON_VALUE" | json-util set rdp_host)
	fi

    echo -e "\n$(date '+%Y-%m-%d %H:%M:%S') - ${GREEN}Created configuration file /etc/i-tee/config.yaml ${NC}" 2>&1 | tee -a $LOGFILE
    echo -e "\n$(date '+%Y-%m-%d %H:%M:%S') - ${YELLOW}Configuration: $JSON ${NC}" 2>&1 | tee -a $LOGFILE

	printf "$JSON" > "/etc/i-tee/config.yaml"
}


itee_magic


### Startup
echo -e "\n$(date '+%Y-%m-%d %H:%M:%S') - ${YELLOW}Pulling Docker images: ${NC}" 2>&1 | tee -a $LOGFILE

docker pull guacamole/guacd &
docker pull keijokapp/guacamole &
wait

docker pull jazzdd/phpvirtualbox &
wait

docker pull rangeforce/i-tee:latest &
docker pull mysql:5.7 &
wait

echo -e "\n$(date '+%Y-%m-%d %H:%M:%S') - ${GREEN}Docker images downloaded ${NC}" 2>&1 | tee -a $LOGFILE

echo "Starting services"
echo -e "\n$(date '+%Y-%m-%d %H:%M:%S') - ${YELLOW}Working with services ${NC}" 2>&1 | tee -a $LOGFILE
sysctl --system

systemctl daemon-reload  2>&1 | tee -a $LOGFILE
systemctl restart docker.service 2>&1 | tee -a $LOGFILE
systemctl enable ferm phpvirtualbox ldap-tunnel mysql nginx guacamole i-tee netdata vboxweb-service  2>&1 | tee -a $LOGFILE
systemctl restart ferm  2>&1 | tee -a $LOGFILE
systemctl restart phpvirtualbox ldap-tunnel mysql nginx guacamole i-tee netdata vboxweb-service  2>&1 | tee -a $LOGFILE
systemctl restart docker.service
echo -e "\n$(date '+%Y-%m-%d %H:%M:%S') - ${GREEN}Services enabled and started ${NC}" 2>&1 | tee -a $LOGFILE

echo -e "\n$(date '+%Y-%m-%d %H:%M:%S') - ${YELLOW}Currently running containers: ${NC}\n" 2>&1 | tee -a $LOGFILE

/usr/bin/docker ps 2>&1 | tee -a $LOGFILE

if [ ! -f /etc/nginx/htpasswd ]
then
echo -e "\n$(date '+%Y-%m-%d %H:%M:%S') - ${YELLOW}Generating new password for phpvirtualbox: ${NC}" 2>&1 | tee -a $LOGFILE
PHPVIRTUALBOX_ADMIN_PASSWORD=$(pwgen 20 1)
echo -e "\n$(date '+%Y-%m-%d %H:%M:%S') - ${GREEN}Password for phpvirtualbox successfully generated: ${NC} $PHPVIRTUALBOX_ADMIN_PASSWORD" 2>&1 | tee -a $LOGFILE
echo "phpvirtualbox username: admin, password: $PHPVIRTUALBOX_ADMIN_PASSWORD" >> /root/i-tee-passwords.txt
echo "$PHPVIRTUALBOX_ADMIN_PASSWORD" | htpasswd -ci /etc/nginx/htpasswd  admin

echo -e "\n$(date '+%Y-%m-%d %H:%M:%S') - ${YELLOW}Adding correct admin rights for phpvirtualbox ${NC}" 2>&1 | tee -a $LOGFILE
PHPVIRTUALBOX_ADMIN_HASH=$(echo -n $PHPVIRTUALBOX_ADMIN_PASSWORD|sha512sum|cut -f1 -d' ')
su - vbox -c"vboxmanage setextradata global phpvb/users/admin/pass $PHPVIRTUALBOX_ADMIN_HASH"
su - vbox -c"vboxmanage setextradata global phpvb/users/admin/admin 1"
fi
echo -e "\n$(date '+%Y-%m-%d %H:%M:%S') - ${YELLOW}Creating vboxnet0 netowork${NC}" 2>&1 | tee -a $LOGFILE
vboxmanage hostonlyif create
vboxmanage hostonlyif ipconfig vboxnet0 --ip 172.18.0.1

while [ $(docker inspect -f {{.State.Running}} mysql) != "true" ]; do
	echo "Waiting for MySQL..."
	sleep 2
done

# Filling I-Tee database
echo -e "\n$(date '+%Y-%m-%d %H:%M:%S') - ${YELLOW}FIlling I-Tee database ${NC}" 2>&1 | tee -a $LOGFILE
docker exec -ti i-tee rake db:migrate RAILS_ENV=production


echo -e "\n$(date '+%Y-%m-%d %H:%M:%S') - ${YELLOW}Deleting default guacamole user ${NC}" 2>&1 | tee -a $LOGFILE
docker exec -i mysql mysql -uguacamole -p"$GUACAMOLE_PASSWORD" <<< "update guacamole.guacamole_user set disabled='1' where username='guacadmin';"
docker exec -i mysql mysql -uguacamole -p"$GUACAMOLE_PASSWORD" <<< "select * from guacamole.guacamole_user where username='guacadmin';"


echo -e "\n$(date '+%Y-%m-%d %H:%M:%S') - ${YELLOW}Installing VboxManager with memcache ${NC}" 2>&1 | tee -a $LOGFILE

cd /var/labs/
git clone https://bitbucket.org/rangeforce/vboxmanager.git
cd vboxmanager
/bin/bash setup.sh


echo -e "\n$(date '+%Y-%m-%d %H:%M:%S') - ${YELLOW}Installing Guacamole-proxy ${NC}" 2>&1 | tee -a $LOGFILE

mkdir -p /var/guacamole-proxy
git clone https://bitbucket.org/rangeforce/guacamole-proxy.git /var/guacamole-proxy
sudo useradd -U -r -d /var/guacamole-proxy guacamole
chown guacamole:guacamole /var/guacamole-proxy
cd /var/guacamole-proxy
npm install --save bunyan
npm install --save bunyan-syslog
npm install --save guacamole-lite
chown guacamole:guacamole /var/guacamole-proxy
chmod 750 /var/guacamole-proxy

cat > /usr/local/lib/systemd/system/guacamole-proxy.service <<EOL
[Unit]
Description=Guacamole Proxy server
Requires=guacd.service
After=guacd.service

[Service]
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=guacamole
User=guacamole
Environment=GUAC_SECRET=$GUAC_TOKEN
Environment=WEBSOCKET_PORT=6666
ExecStart=/usr/bin/nodejs /var/guacamole-proxy/app.js
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOL

systemctl daemon-reload
systemctl enable guacamole-proxy.service
systemctl start guacamole-proxy.service
systemctl status guacamole-proxy.service

echo -e "\n$(date '+%Y-%m-%d %H:%M:%S') - ${GREEN}I-Tee installed and should be availiable at https://$(hostname -f)/ ${NC}" 2>&1 | tee -a $LOGFILE

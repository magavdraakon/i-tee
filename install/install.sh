#!/bin/bash

set -e

export LC_ALL=C

echo "Starting i-tee installation script ${BASH_SOURCE[0]}"

if [ $UID -ne 0 ]
then
	echo "Not root! Exiting..."
	echo "Start ${BASH_SOURCE[0]} as a root!"
	exit 1
fi

cd "$( dirname "${BASH_SOURCE[0]}" )"
### Disk tuning

echo 1 > /proc/sys/vm/dirty_background_ratio
echo 80 > /proc/sys/vm/dirty_ratio

### Download necessary tools



curl -L https://github.com/keijokapp/json-util/releases/download/1.0/json-util -o /usr/local/bin/json-util
chmod +x /usr/local/bin/json-util

apt-get update > /dev/null
apt-get install --no-install-recommends -y rsync curl ssh hostname ferm ssl-cert nginx apache2-utils pwgen


### Install static files
set +e
cp ./etc/apt/sources.list.d/virtualbox.list /etc/apt/sources.list.d/virtualbox.list
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

### Create users, groups and respective directories

set +e
mkdir -p /var/labs
useradd -d /var/labs vbox
set -e

mkdir -p /var/labs/.config
chown vbox:vbox /var/labs -R
chmod u+s,g+s /var/labs -R

# Password is needed for phpVirtualbox
VBOX_PASSWORD=$(< /dev/urandom tr -dc _A-Za-z0-9 | head -c20)
echo "vbox:$VBOX_PASSWORD" | chpasswd

### Install packages

install_docker() {
	apt-get remove docker docker-engine docker.io

	apt-get install --no-install-recommends \
		apt-transport-https \
    		curl \
    		software-properties-common
	curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

	add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

	apt-get install -y --no-install-recommends \
		linux-image-extra-$(uname -r) \
		linux-image-extra-virtual


	apt-get update
	apt-get install -y docker-ce

}

install_virtualbox() {
	echo "Installing packages"

	wget -q https://www.virtualbox.org/download/oracle_vbox_2016.asc -O- | sudo apt-key add -
	wget -q https://www.virtualbox.org/download/oracle_vbox.asc -O- | sudo apt-key add -

	apt update
	apt install --no-install-recommends -y virtualbox-5.1 gcc make
	apt dist-upgrade -y

	adduser vbox vboxusers

	VERSION=$(apt-cache policy virtualbox-5.1 | grep Installed: | cut -f2 -d: | cut -f1 -d- | cut -f2 -d' ')
	SUBVERSION=$(apt-cache policy virtualbox-5.1 | grep Installed: | cut -f2 -d: | cut -f1 -d~ | cut -f2 -d' ')

	curl "http://download.virtualbox.org/virtualbox/$VERSION/Oracle_VM_VirtualBox_Extension_Pack-$SUBVERSION.vbox-extpack" > \
		"/tmp/Oracle_VM_VirtualBox_Extension_Pack-$SUBVERSION.vbox-extpack"
	vboxmanage extpack install --replace "/tmp/Oracle_VM_VirtualBox_Extension_Pack-$SUBVERSION.vbox-extpack"
	su - vbox -c "vboxmanage extpack install --replace '/tmp/Oracle_VM_VirtualBox_Extension_Pack-$SUBVERSION.vbox-extpack'" || true
	su - vbox -c "vboxmanage setproperty vrdeauthlibrary VBoxAuthSimple"

	apt-mark hold virtualbox-5.1
}

install_docker
install_virtualbox

### Cleanup

echo "Deleting containers"
set +e
docker rm -f phpvirtualbox netdata i-tee mysql guacamole guacd
set -e

### Set up phpVirtualbox

mkdir /etc/phpvirtualbox -p
echo "VBOX_PASSWORD=$VBOX_PASSWORD" > /etc/phpvirtualbox/environment

# Setup SSH between host and I-Tee container

docker run --rm --add-host host.local:172.17.0.1 --entrypoint ssh-keyscan iadknet/ssh-client-light 172.17.0.1 > /etc/i-tee/known_hosts
if [ ! -f /etc/i-tee/id_rsa ] || [ ! -f /var/labs/.ssh/authorized_keys ]
then
	ssh-keygen -t rsa -b 2048 -N "" -f /etc/i-tee/id_rsa
	mkdir -p /var/labs/.ssh
	mv /etc/i-tee/id_rsa.pub /var/labs/.ssh/authorized_keys
	chown vbox:vbox /var/labs/.ssh -R
fi

# Configure SSL keys used by proxy

set +e
# These commands will not overwrite existing files
ln -s /etc/ssl/certs/ssl-cert-snakeoil.pem /etc/ssl/private/i-tee.crt
ln -s /etc/ssl/private/ssl-cert-snakeoil.key /etc/ssl/private/i-tee.key
set -e

# Create I-Tee configuration and install MySQL database

itee_magic() {

	ITEE_PASSWORD=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c20)
	GUACAMOLE_PASSWORD=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c20)

	SQL=
	SQL="$SQL CREATE DATABASE IF NOT EXISTS itee;\n"
	SQL="$SQL CREATE DATABASE IF NOT EXISTS guacamole;\n"

	SQL="$SQL CREATE USER itee IDENTIFIED BY '$ITEE_PASSWORD';\n"
	SQL="$SQL GRANT ALL ON itee.* TO itee;\n"
	SQL="$SQL GRANT ALL ON guacamole.* TO itee;\n"

	SQL="$SQL CREATE USER guacamole IDENTIFIED BY '$GUACAMOLE_PASSWORD';\n"
	SQL="$SQL GRANT ALL ON guacamole.* TO guacamole;\n"

	echo "Initializing database"
	rm -rf /opt/mysql/data

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
		echo "Database not ready..."
	done

	docker stop $MYSQL_ID

	echo "Database initialized"

	echo "Generating configuretion"

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
		echo "Warning: LDAP is not configured" >&2
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

	echo "Configuration: $JSON"

	printf "$JSON" > "/etc/i-tee/config.yaml"
}


itee_magic


### Startup

echo "Pulling images"

docker pull guacamole/guacd &
docker pull keijokapp/guacamole &
wait

docker pull titpetric/netdata &
docker pull keijokapp/phpvirtualbox &
wait

docker pull rangeforce/i-tee:latest &
docker pull mysql:5.7 &
wait

echo "Starting services"

sysctl --system

systemctl daemon-reload
systemctl enable ferm phpvirtualbox ldap-tunnel mysql nginx guacamole i-tee netdata vboxweb-service
systemctl restart ferm
systemctl restart phpvirtualbox ldap-tunnel mysql nginx guacamole i-tee netdata vboxweb-service

if [ ! -f /etc/nginx/htpasswd ]
then
echo "Generating new password for phpvirtualbox"
PHPVIRTUALBOX_ADMIN_PASSWORD=$(pwgen 20 1)
echo "phpvirtualbox username: admin, password: $PHPVIRTUALBOX_ADMIN_PASSWORD" >> /root/i-tee-passwords.txt
echo "$PHPVIRTUALBOX_ADMIN_PASSWORD" | htpasswd -ci /etc/nginx/htpasswd  admin

PHPVIRTUALBOX_ADMIN_HASH=$(echo -n $PHPVIRTUALBOX_ADMIN_PASSWORD|sha512sum|cut -f1 -d' ')
su - vbox -c"vboxmanage setextradata global phpvb/users/admin/pass $PHPVIRTUALBOX_ADMIN_HASH"
fi

vboxmanage hostonlyif create
vboxmanage hostonlyif ipconfig vboxnet0 --ip 172.18.0.1




# Filling I-Tee database

docker exec -ti i-tee rake db:migrate RAILS_ENV=production

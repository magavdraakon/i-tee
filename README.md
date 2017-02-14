# About i-tee
i-tee is a distance laboratory system, that is based on ruby on rails and uses VirtualBox headless virtualization.

i-tee is developed by the Estonian IT College.

More information about i-tee and one lab (we call them a learningspace) can be found from following article:
http://conferences.sigcomm.org/sigcomm/2015/pdf/papers/p113.pdf


    Margus Ernits, Johannes Tammekänd, and Olaf Maennel. 2015. 
    i-tee: A fully automated Cyber Defense Competition for Students. 
    In Proceedings of the 2015 ACM Conference on Special Interest Group on Data Communication (SIGCOMM '15). 
    ACM, New York, NY, USA, 113-114. DOI=http://dx.doi.org/10.1145/2785956.2790033


i-tee contains three layers such as: Virtualisation, Web frontend (access control, lab control), Learningspace layer.

# Installation

This section describes sample installation of I-Tee on Ubuntu Server 16.04 LTS.

## Virtualization environment

I-Tee currently uses VirtualBox headless for virtualization and SSH to run `vboxmanage` commands on virtualization host.

 1. Create dedicated user `vbox` for VirtualBox, preferably with separate Btrfs partition as home directory (e.g. `/var/labs`).
 2. Install VirtualBox 5.1 and VirtualBox Extension Packs.
```sh
echo "$(curl http://download.virtualbox.org/virtualbox/debian/oracle_vbox_2016.asc)" | apt-key add -
echo "$(curl https://get.docker.com/)" | sh -s # avoid direct pipe from curl to shell (or any other program)

apt install -y virtualbox-5.1

VERSION=$(apt policy virtualbox-5.1 |grep Installed:| cut -f2 -d: |cut -f1 -d-|cut -f2 -d' ')
SUBVERSION=$(apt policy virtualbox-5.1 |grep Installed:| cut -f2 -d: |cut -f1 -d~|cut -f2 -d' ')

curl "http://download.virtualbox.org/virtualbox/$VERSION/Oracle_VM_VirtualBox_Extension_Pack-$SUBVERSION.vbox-extpack" > \
	"/tmp/Oracle_VM_VirtualBox_Extension_Pack-$SUBVERSION.vbox-extpack"
vboxmanage extpack install --replace "/tmp/Oracle_VM_VirtualBox_Extension_Pack-$SUBVERSION.vbox-extpack"
su vbox -c "vboxmanage extpack install --replace '/tmp/Oracle_VM_VirtualBox_Extension_Pack-$SUBVERSION.vbox-extpack'" || true
```

## Install and set up database

 1. Install MySQL.
 2. Create MySQL users and databases for I-Tee and Guacamole (e.g. `itee` and `guacamole`)

## Installing reverse proxy server

It's recommended to run application behind TLS-terminating reverse proxy and make then direclty inaccessible.

 1. Install Nginx.
 3. Add TLS key/certificate to `/etc/ssl/private/i-tee.key`/`/etc/ssl/certs/i-tee.crt`.
 2. Configure site (e.g. `/etc/nginx/sites-available/default`):
```
server {
	listen 80;
	return         301 https://$host$request_uri;
}

server {
	listen 443;

	ssl on;
	ssl_certificate /etc/ssl/certs/i-tee.crt;
	ssl_certificate_key /etc/ssl/private/i-tee.key;

	location / {
		proxy_pass http://172.17.0.1:8080/;

		# I-Tee might need some time to respond
		proxy_connect_timeout       3600;
		proxy_send_timeout          3600;
		proxy_read_timeout          3600;
		send_timeout                3600;
	}

	location /guacamole/ {
		proxy_pass http://172.17.0.1:8081/guacamole/;
		proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
		proxy_set_header Upgrade $http_upgrade;
		proxy_set_header Connection $http_connection;
	}

	location /virtualbox/ {
		proxy_pass http://172.17.0.1:4433/;
	}
}
```

## Installing I-Tee web application

I-Tee has been designed and tested to run inside Docker container, although it should also be capable of running in normal Linux environment.
Refer [`Dockerfile`](Dockerfile) for installation instructions.

 1. Install Docker.
 2. Create configuration file `/etc/i-tee/config.yaml`. (use [`docker/config_sample.yaml`](docker/config_sample.yaml) as an example)
 3. Create SSH keypair to access virtualization host. Add public key to `authorized_keys` file of VirtualBox user (i.e `/var/labs/.ssh/authorized_keys` for `vbox`) on virtualization host.
 4. Create SSH `/etc/i-tee/known_hosts` file to let I-Tee verify virtualization host. It's syntax is `server-host-name key-type server-public-key`.
 5. Create systemd unit file (e.g. `/usr/local/lib/systemd/system/i-tee.service`)
```
[Unit]
Requires=docker.service
After=docker.service

[Install]
WantedBy=multi-user.target

[Service]
EnvironmentFile=/etc/i-tee/environment
ExecStartPre=-/usr/bin/env docker rm -f i-tee
ExecStartPre=/usr/bin/env docker create -t \
	--name i-tee \
	--publish "172.17.0.1:8080:80" \
	--env "ITEE_SECRET_TOKEN=6ddd9b0760edb09b4cade3892628fad4d182c6675ee7c1e151ced0cb8c952cb75e17b5654342746ba5640b63844f6f162246201aff936a8da154104f29b1959d" \
	--env "VBOX_HOST=172.17.0.1" \
	--env "VBOX_PORT=22" \
	--env "VBOX_USER=vbox" \
	--volume /etc/i-tee/config.yaml:/etc/i-tee/config.yaml:ro \
	--volume /etc/i-tee/id_rsa:/root/.ssh/id_rsa:ro \
	--volume /etc/i-tee/known_hosts:/root/.ssh/known_hosts:ro \
	--volume /var/labs/exports:/var/labs/exports \
	keijokapp/i-tee:latest
ExecStart=/usr/bin/env docker start -a i-tee
ExecStop=/usr/bin/env docker stop i-tee
SuccessExitStatus=143
Restart=always
RestartSec=3
```
 4. Enable and start systemd unit.

## Installing Guacamole

I-Tee can be used with Guacamole to enable access to RDP via web browser. We recommend Docker-based installation.
Two applications are needed for Guacamole - `guacd` which acts as configuration- and stateless Guacamole protocol proxy
and `guacamole` which serves the application.

 1. Install Docker. (TODO: reference to instructions)
 2. Run `docker run --rm guacamole/guacamole /opt/guacamole/bin/initdb.sh --mysql` to get get database initialization script and run it in your Guacamole database.
 3. Create systemd unit files for `guacd` and `guacamole`.


 `guacd` (e.g. `/usr/local/lib/systemd/system/guacd.service`):
```
[Unit]
Requires=docker.service
After=docker.service

[Install]
WantedBy=multi-user.target

[Service]
ExecStartPre=-/usr/bin/env docker rm -f guacd
ExecStartPre=/usr/bin/env docker create -t \
	--name guacd \
	--publish "172.170.1:4822:4822" \
	glyptodon/guacd
ExecStart=/usr/bin/env docker start -a guacd
ExecStop=/usr/bin/env docker stop guacd
SuccessExitStatus=143
Restart=always
```

 `guacamole` (e.g. `/usr/local/lib/systemd/system/guacamole.service`)
```
[Unit]
Requires=guacd.service
Requires=docker.service
After=docker.service

[Install]
WantedBy=multi-user.target

[Service]
ExecStartPre=-/usr/bin/env docker rm -f guacamole
ExecStartPre=/usr/bin/env docker create -t \
	--env GUACD_PORT_4822_TCP_ADDR=172.17.0.1 \
	--env GUACD_PORT_4822_TCP_PORT=4822 \
	--env MYSQL_HOSTNAME=172.17.0.1 \
	--env MYSQL_PORT=3306 \
	--env MYSQL_DATABASE=guacamole \
	--env MYSQL_USER=guacamole \
	--env MYSQL_PASSWORD=mysql_guacamole_password \
	--name guacamole \
	--publish "172.17.0.1:8081:8080" \
	glyptodon/guacamole
ExecStart=/usr/bin/env docker start -a guacamole
ExecStop=/usr/bin/env docker stop guacamole
SuccessExitStatus=143
Restart=always
RestartSec=3
```

 4. Enable and start created unit files.

# Authors
Tiia Tänav

Margus Ernits

Carolyn Fischer (retired)

Aivar Guitar (retired)

Madis Toom (retired)


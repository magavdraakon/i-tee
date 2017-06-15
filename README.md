**Current maintainer's note:** What first started as a college project, has over time become a total mess - no comprehensive documentation, automated tests, flexible logging and monitoring support, ..., not to mention countless edge-case & security bugs, shitty architecture and horrible code quality.
It's hard to fix any of these problems without complete rewrite, so I leave you with this minimal README. We are [slowly] developing new microservice-based system, while still trying to maintain this beast.

If you need any operational and/or development support, feel free to create an issue or contact with maintainer(s) via email:

 * [sl2mmin](https://github.com/sl2mmin) ([roland.kaur@itcollege.ee](mailto:roland.kaur@itcollege.ee)) - project lead
 * [keijokapp](https://github.com/keijokapp) ([keijo.kapp@itcollege.ee](mailto:keijo.kapp@itcollege.ee)) - Ruby-unfriendly maintainer/developer/architect, happy to solve any technical problem as long as it doesn't involve integrating "small" random feature into already hard-to-maintain system

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

This section describes sample installation of I-Tee on Ubuntu Server 16.04 LTS.

# Running

## Virtualization environment

I-Tee currently uses VirtualBox headless for virtualization and OpenSSH to run `vboxmanage` commands on virtualization host.

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

## Guacamole

I-Tee has some hacky support for Guacamole web client. Read [Guacamole User's Guide Chapter 3 - Installing Guacamole with Docker](https://guacamole.incubator.apache.org/doc/gug/guacamole-docker.html) for instruction about running Guacamole.
If you get it working, put database credentials and other Guacamole-related settings to I-Tee configuration file and it *might* be enough.

**Important:** The Guacamole support is so hacky that it does not work with newer Guacamole images, so you need to use older one referred by `keijokapp/guacamole`.

## I-Tee web application

I-Tee has been designed and tested to run inside Docker container, although it should also (in some way) be capable of running in normal Linux environment.
Refer [`Dockerfile`](Dockerfile) for installation instructions without Docker. The container does not need to be in the same physical machine with hypervisor
but there might be some problems if connection is not stable enough.

Docker command to run I-Tee would be something like this:
```sh
docker create -t \
        --name i-tee \
        --publish "8080:80" \
        --env "ITEE_SECRET_TOKEN=6ddd9b0760edb09b4cade3892628fad4d182c6675ee7c1e151ced0cb8c952cb75e17b5654342746ba5640b63844f6f162246201aff936a8da154104f29b1959d" \
        --env "VBOX_HOST=172.17.0.1" \
        --env "VBOX_PORT=22" \
        --env "VBOX_USER=vbox" \
        --volume /etc/i-tee/config.yaml:/etc/i-tee/config.yaml:ro \
        --volume /etc/i-tee/id_rsa:/root/.ssh/id_rsa:ro \
        --volume /etc/i-tee/known_hosts:/root/.ssh/known_hosts:ro \
        --volume /var/labs/exports:/var/labs/exports \
        keijokapp/i-tee:latest
```
 * `ITEE_SECRET_TOKEN` - 64-byte hex-encoded token used to sign cookies (replace it with your random token)
 * `VBOX_HOST` - address of hypervisor host to be connected to via SSH.
 * `VBOX_PORT` - hypervisor SSH server port (defaults to 22)
 * `VBOX_USER` - user used to run virtual machines
 * `/etc/i-tee/config.yaml` - I-Tee configuration file (see [`docker/config_sample.yaml`](docker/config_sample.yaml))
 * `/root/.ssh/id_rsa` - SSH private key used to connect to hypervisor
 * `/root/.ssh/known_hosts` - SSH known_hosts file containing record for public key of specified hypervisor host
 * `/root/.ssh/exports` - directory used to export/import/backup lab data as directories of JSON files

# Authors
Tiia Tänav

Margus Ernits

Carolyn Fischer (retired)

Aivar Guitar (retired)

Madis Toom (retired)


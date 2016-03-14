#!/bin/bash

VBoxManage extpack uninstall "Oracle VM VirtualBox Extension Pack"
su - vbox -c'vboxmanage extpack uninstall "Oracle VM VirtualBox Extension Pack"'

VER=$(apt-cache policy virtualbox-5.0 |grep Installed:| cut -f2 -d: |cut -f1 -d-|cut -f2 -d' ')
SUBVER=$(apt-cache policy virtualbox-5.0 |grep Installed:| cut -f2 -d: |cut -f1 -d~|cut -f2 -d' ')

echo $VER
echo $SUBVER

cd /tmp 

wget http://download.virtualbox.org/virtualbox/${VER}/Oracle_VM_VirtualBox_Extension_Pack-${SUBVER}.vbox-extpack
VBoxManage extpack install Oracle_VM_VirtualBox_Extension_Pack-${SUBVER}.vbox-extpack


VBoxManage list extpacks

su - vbox -c'VBoxManage list extpacks'

su - vbox -c'VBoxManage extpack install Oracle_VM_VirtualBox_Extension_Pack-${SUBVER}.vbox-extpack'



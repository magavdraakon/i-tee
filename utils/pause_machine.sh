#!/bin/bash
if [ $# -ne 1 ]
then 
echo "anna masina nimi"

exit 1
fi

NAME=$1

#TODO ensure that VM exists

echo "pausin virtuaalmasina $NAME"
#for libvirt 
#virsh -c qemu:///system suspend $NAME

#for VirtualBox
sudo -u vbox VBoxManage controlvm  pause $NAME

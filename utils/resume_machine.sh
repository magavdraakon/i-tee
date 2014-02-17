#!/bin/bash
if [ $# -ne 1 ]
then 
echo "anna masina nimi"

exit 1
fi

NAME=$1

echo "taastan virtuaalmasina $NAME"
#For libvirt
#virsh -c qemu:///system resume $NAME

#For VirtualBox
/usr/bin/VBoxManage controlvm $NAME resume


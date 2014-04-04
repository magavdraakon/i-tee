#!/bin/bash
# Author: Margus Ernits margus.ernits@gmail.com

if [ $# -ne 5 ]
then 
echo "Five arguments as mac IP template name password"
exit 1
fi

id | grep vboxusers > /dev/null


if [ $? -eq 0 ]
then
    echo "Using $(id) to execute virtual machines"
else
    echo "Script is started with user $(id)"
    echo "Please add user to vboxusers group or use other user who able to start VirtualBox machines"
    exit 1
fi

echo "script ended"

ADMIN=mernits@itcollege.ee

MAC=$1
IP_ADDR=$2
TEMPLATE=$3
NAME=$4
PWD=$5
#VIRT_DIR="/var/lib/libvirt/images"
#IMAGE=$VIRT_DIR/$NAME.img
#XML=/etc/libvirt/qemu/$NAME.xml




echo "tekitan virtuaalmasina $NAME template-ist $TEMPLATE Mac aadressiga $MAC"
if [ $(VBoxManage list vms | cut -f1 -d' '| tr -d '"'| grep $NAME ) ]
then
	echo "machine already exists. Starting old instance of $NAME"
	#time VBoxManage start $NAME
else
    SNAPSHOT=$(vboxmanage snapshot $TEMPLATE list|grep '*'|grep template|awk '{print $2}')
    echo $(vboxmanage snapshot $TEMPLATE list|grep '*'|grep template)
    if [ $SNAPSHOT ]
        then
            echo "Cloning $NAME using $TEMPLATE and snapshot $SNAPSHOT"
            #echo "time VBoxManage clonevm  $TEMPLATE --snapshot $SNAPSHOT --options link --name $NAME --register"
            time VBoxManage clonevm  $TEMPLATE --snapshot $SNAPSHOT --options link --name $NAME --register
        else
            echo "cloning $NAME using $TEMPLATE"
            time VBoxManage clonevm $TEMPLATE --name $NAME --register
        fi
fi

if [ $? -ne 0 ]
then
#echo "Clone VM failed"
echo "Virtual Machine clonig fails $TEMPLATE $NAME" 
#| mail $ADMIN -s $(hostname -f)
exit 1
fi

USERNAME=${NAME##*-}
GROUPNAME=${NAME:0:((${#NAME}-${#USERNAME})-1)}
VBoxManage modifyvm $NAME --groups "/${GROUPNAME}","/${USERNAME}"


PWDHASH=$(VBoxManage internalcommands passwordhash $PWD|cut -f3 -d' ')
VBoxManage setextradata $NAME  "VBoxAuthSimple/users/${USERNAME}" $PWDHASH


INTERNALNETNAME=$(date +%Y)${USERNAME}

VBoxManage modifyvm $NAME  --intnet2 $INTERNALNETNAME

RDP_PORT=${IP_ADDR##*.}
VBoxManage modifyvm $NAME --vrdeport 10$RDP_PORT

VBoxManage startvm $NAME --type headless

if [ $? -ne 0 ]
then
#echo "Starting VM failed"
echo "Virtual Machine start from $TEMPLATE with name: $NAME Failed" 
#| mail $ADMIN -s $(hostname -f)
exit 1
fi

echo "masin $NAME loodud"
#echo "VM named: $NAME created"


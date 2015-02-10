#!/bin/bash
# Author: Margus Ernits margus.ernits@gmail.com

if [ $# -ne 6 ]
then 
echo "Five arguments as mac IP template name password"
exit 1
fi

function die {
echo "Error with $1"
echo "ERROR"
exit 1
}

id | grep vboxusers > /dev/null


if [ $? -eq 0 ]
then
    echo "Using $(id) to execute virtual machines"
else
    echo "Script is started with user $(id)"
    echo "Please add user to vboxusers group or use other user who able to start VirtualBox machines"
    exit 1
fi

#echo "script ended"

ADMIN=mernits@itcollege.ee

MAC=$1
IP_ADDR=$2
TEMPLATE=$3
NAME=$4
USER_PWD=$5
ENVIRONMENT=$6

[ -r "$ENVIRONMENT" ] && . "$ENVIRONMENT" || echo "no environment $ENVIRONMENT variables from RAILS" > /var/tmp/info.log

[ -r "$RUNDIR"/"$NAME".sh ] && . "$RUNDIR"/"$NAME".sh || echo "no machine specific variables for customizing VM in "$RUNDIR"/"$NAME".sh" >> /var/tmp/info.log



env >> /var/tmp/info.log

echo "tekitan virtuaalmasina $NAME template-ist $TEMPLATE Mac aadressiga $MAC"
if [ $(VBoxManage list vms | cut -f1 -d' '| tr -d '"'| grep "^$NAME$" ) ]
then
	echo "machine already exists. Starting old instance of $NAME"
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
#TODO to get vm's directory vboxmanage showvminfo vm_name|grep 'Config file:'
USERNAME=${NAME##*-}
GROUPNAME=${NAME:0:((${#NAME}-${#USERNAME})-1)}
VBoxManage modifyvm $NAME --groups "/${GROUPNAME}","/${USERNAME}"


PWDHASH=$(VBoxManage internalcommands passwordhash $USER_PWD|cut -f3 -d' ')
VBoxManage setextradata $NAME  "VBoxAuthSimple/users/${USERNAME}" $PWDHASH

VBoxManage setextradata $NAME      "VBoxInternal/Devices/pcbios/0/Config/DmiSystemProduct"     "System Product"
VBoxManage setextradata $NAME      "VBoxInternal/Devices/pcbios/0/Config/DmiSystemVersion"     "System Version"
VBoxManage setextradata $NAME      "VBoxInternal/Devices/pcbios/0/Config/DmiSystemSerial"      "System Serial"
VBoxManage setextradata $NAME      "VBoxInternal/Devices/pcbios/0/Config/DmiSystemSKU"         "System SKU"
VBoxManage setextradata $NAME      "VBoxInternal/Devices/pcbios/0/Config/DmiSystemFamily"      "System Family"

#if special networks are set then rewrite NIC setup
declare -f set_networks >/dev/null && set_networks || {
echo "No network setup"
INTERNALNETNAME=$(date +%Y)${USERNAME}
VBoxManage modifyvm $NAME  --intnet2 $INTERNALNETNAME
}

RDP_PORT=${IP_ADDR##*.}
VBoxManage modifyvm $NAME --vrdeport 10$RDP_PORT

VBoxManage setextradata $NAME "VBoxInternal/Devices/pcbios/0/Config/DmiSystemVendor" "I-tee Distance Laboratory System"

# dmidecode -s bios-version
VBoxManage setextradata $NAME "VBoxInternal/Devices/pcbios/0/Config/DmiBIOSVersion"       "${NAME}"

# dmidecode -s bios-release-date
VBoxManage setextradata $NAME "VBoxInternal/Devices/pcbios/0/Config/DmiBIOSReleaseDate"   "${USERNAME}"

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


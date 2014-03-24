#!/bin/bash
#this script needs some error handling (if image does not exists or can't be copied to new location) - Margus Ernits
#TODO get important paremeters from config (ADMIN, VIRT_DIR, XML, etc)
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


#TODO SSH pordi suunamine VBoxManage abil

ADMIN=mernits@itcollege.ee

MAC=$1
IP_ADDR=$2
TEMPLATE=$3
NAME=$4
PWD=$5
VIRT_DIR="/var/lib/libvirt/images"
IMAGE=$VIRT_DIR/$NAME.img
XML=/etc/libvirt/qemu/$NAME.xml




echo "tekitan virtuaalmasina $NAME template-ist $TEMPLATE Mac aadressiga $MAC"
#TODO test if --name exists then remove old one
if [ $(VBoxManage list vms | cut -f1 -d' '| tr -d '"'| grep $NAME ) ]
then
	echo "machine already exists. Starting old instance of $NAME"
	#time VBoxManage start $NAME
else
	echo "cloning $NAME"
	time VBoxManage clonevm $TEMPLATE --name $NAME --register
fi

if [ $? -ne 0 ]
then
#echo "Clone VM failed"
echo "Virtual Machine clonig fails $TEMPLATE $NAME" 
#| mail $ADMIN -s $(hostname -f)
exit 1
fi


PWDHASH=$(VBoxManage internalcommands passwordhash $PWD|cut -f3 -d' ')
VBoxManage setextradata $NAME  "VBoxAuthSimple/users/${NAME##*-}" $PWDHASH


#VBoxManage modifyvm ubuntu-server-mernits  --intnet2 "2014mernits"

INTERNALNETNAME=$(date +%Y)${NAME##*-}

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


exit 0

for try in $(seq 1 20); do
  ping -c1 $IP_ADDR
  if [ $? -eq 0 ]; then
    break
  else
    echo "Waiting...$try"
  fi
done
#SSH service ei pruugi veel töötada ja ootame mõne aja TODO - korralikumalt teha
sleep 5
cat | ssh -i /etc/itcollege/id_dsa -o 'StrictHostKeyChecking=no' root@$IP_ADDR << LOPP
passwd student
$PWD
$PWD
LOPP

ssh -i /etc/itcollege/id_dsa -o 'StrictHostKeyChecking=no' root@$IP_ADDR uptime

if [ $? -ne 0 ]
then
  echo "Problem connecting to the host"
  exit 1
fi

echo "masin $NAME loodud"


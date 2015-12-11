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
FULLNAME=$7

logger -p info -t i-tee VM ${NAME} starting

[ -r "$ENVIRONMENT" ] && . "$ENVIRONMENT" || logger -p err -t i-tee  "no environment $ENVIRONMENT variables from RAILS"

[ -r "$RUNDIR"/"$NAME".sh ] && . "$RUNDIR"/"$NAME".sh || echo "no machine specific variables for customizing VM in "$RUNDIR"/"$NAME".sh" >> /var/tmp/info.log


echo "tekitan virtuaalmasina $NAME template-ist ${TEMPLATE} Mac aadressiga $MAC"


FIRST_START=false

if [ $(VBoxManage list vms | cut -f1 -d' '| tr -d '"'| grep "^$NAME$" ) ]
then
	echo "machine already exists. Starting old instance of $NAME"
else
    SNAPSHOT=$(vboxmanage snapshot ${TEMPLATE} list|grep '*'|grep template|awk '{print $2}')
    echo $(vboxmanage snapshot ${TEMPLATE} list|grep '*'|grep template|awk '{print $2}')
    if [ $SNAPSHOT ]
    then
        echo "Cloning $NAME using ${TEMPLATE} and snapshot $SNAPSHOT"
        #echo "time VBoxManage clonevm  ${TEMPLATE} --snapshot $SNAPSHOT --options link --name $NAME --register"
        time VBoxManage clonevm  ${TEMPLATE} --snapshot $SNAPSHOT --options link --name $NAME --register
    else
        echo "cloning $NAME using ${TEMPLATE}"
        time VBoxManage clonevm ${TEMPLATE} --name $NAME --register
    fi
    FIRST_START=true
fi

if [ $? -ne 0 ]
then
#echo "Clone VM failed"
echo "Virtual Machine clonig fails ${TEMPLATE} $NAME"
#| mail $ADMIN -s $(hostname -f)
exit 1
fi
#TODO to get vm's directory vboxmanage showvminfo vm_name|grep 'Config file:'
USERNAME=${NAME##*-}
GROUPNAME=${NAME:0:((${#NAME}-${#USERNAME})-1)}
VBoxManage modifyvm $NAME --groups "/${GROUPNAME}","/${USERNAME}"


PWDHASH=$(VBoxManage internalcommands passwordhash $USER_PWD|cut -f3 -d' ')
VBoxManage setextradata ${NAME}  "VBoxAuthSimple/users/${USERNAME}" ${PWDHASH}

VBoxManage setextradata ${NAME}      "VBoxInternal/Devices/pcbios/0/Config/DmiSystemProduct"     "System Product"
VBoxManage setextradata ${NAME}      "VBoxInternal/Devices/pcbios/0/Config/DmiSystemVersion"     "System Version"
if [[ -r /var/labs/run/${TEMPLATE}.sh ]]
then
source /var/labs/run/${TEMPLATE}.sh

curl -H 'Content-Type: application/json' -X DELETE -d '{"api_key":"'"${API_KEY_ADMIN}"'", "lab":"'"${LAB_ID}"'", "userName":"'"${USERNAME}"'", "reset":false}' "${LAB_URI}"

#echo "SENT user delete" 'Content-Type: application/json' -X POST -d '{"api_key":"'"${API_KEY_ADMIN}"'", "lab":"'"${LAB_ID}"'", "username":"'"${USERNAME}"'", "password":"'"${USER_PWD}"'", "info":{"answer":"42"}}' "${LAB_URI}"

#curl -H "Content-Type: application/json" -X GET -d '{"api_key":"botkey", "username":"someone"}' http://localhost:3000/api/v1/userkey
USER_KEY=$(curl -H 'Content-Type: application/json' -X POST -d '{"api_key":"'"${API_KEY_ADMIN}"'", "lab":"'"${LAB_ID}"'", "fullname":"'"${FULLNAME}"'", "username":"'"${USERNAME}"'", "password":"'"${USER_PWD}"'", "info":{"answer":"42"}}' "${LAB_URI}" | cut -d'"' -f4 -)

echo USER_KEY is $USER_KEY
logger -p info -t i-tee  "USER_KEY for user ${USERNAME} is $USER_KEY for VM  ${TEMPLATE}"

    VBoxManage setextradata ${NAME}      "VBoxInternal/Devices/pcbios/0/Config/DmiSystemSerial"      "${LAB_ID}/${USER_KEY}"
else
    VBoxManage setextradata ${NAME}      "VBoxInternal/Devices/pcbios/0/Config/DmiSystemSerial"      "System Serial"
fi

VBoxManage setextradata ${NAME}      "VBoxInternal/Devices/pcbios/0/Config/DmiSystemSKU"         "System SKU"
VBoxManage setextradata ${NAME}      "VBoxInternal/Devices/pcbios/0/Config/DmiSystemFamily"      "System Family"

# if special networks are set then rewrite NIC setup
declare -f set_networks > /dev/null && set_networks || {
echo "No network setup"
INTERNALNETNAME=$(date +%Y)${USERNAME}
VBoxManage modifyvm ${NAME}  --intnet2 $INTERNALNETNAME
}


VBoxManage setextradata ${NAME} "VBoxInternal/Devices/pcbios/0/Config/DmiSystemVendor" "I-tee Distance Laboratory System"

# dmidecode -s bios-version
VBoxManage setextradata ${NAME} "VBoxInternal/Devices/pcbios/0/Config/DmiBIOSVersion"       "${NAME}"

# dmidecode -s bios-release-date
VBoxManage setextradata ${NAME} "VBoxInternal/Devices/pcbios/0/Config/DmiBIOSReleaseDate"   "${USERNAME}"



if [ "${FIRST_START}" = "true" ]
then
#connect DVD iso if exists
    if [ -f "/var/labs/ovas/${GROUPNAME}.iso" ]
    then

    VBoxManage storageattach "${NAME}" --storagectl IDE --port 1 --device 0 --type dvddrive --medium "/var/labs/ovas/${GROUPNAME}.iso"

    VBoxManage startvm $NAME --type headless

    sleep 2

    for i in {1..60}
    do

        if [ $(VBoxManage list runningvms | cut -f1 -d' '| tr -d '"'| grep "^$NAME$" ) ]
        then
            sleep 1
        else
            echo "First configuration for ${NAME} done!"
            break
        fi


    done
    VBoxManage controlvm ${NAME} acpipowerbutton && sleep 5
    VBoxManage controlvm ${NAME} poweroff

    VBoxManage storageattach "${NAME}" --storagectl IDE --port 1 --device 0 --medium "none"

    fi
fi

RDP_PORT=${IP_ADDR##*.}
VBoxManage modifyvm ${NAME} --vrdeport 10${RDP_PORT}

VBoxManage startvm ${NAME} --type headless



if [ $? -ne 0 ]
then
#echo "Starting VM failed"
echo "Virtual Machine start from ${TEMPLATE} with name: $NAME Failed"
#| mail $ADMIN -s $(hostname -f)
exit 1
fi

#TODO - return something else (get rid of masin $NAME loodud)
echo "masin $NAME loodud"
#echo "VM named: $NAME created"


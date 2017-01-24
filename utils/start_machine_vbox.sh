#!/bin/bash
# Author: Margus Ernits margus.ernits@gmail.com

if [ $# -ne 7 ]
then
echo "7 arguments are needed!"
exit 1
fi

IT_HOSTNAME=$1
IP_ADDR=$2
TEMPLATE=$3
NAME=$4
USER_PWD=$5
ENVIRONMENT=$6
FULLNAME=$7

logger -p info -t i-tee VM ${NAME} starting

[ -r "$ENVIRONMENT" ] && . "$ENVIRONMENT" || logger -p err -t i-tee  "no environment $ENVIRONMENT variables from RAILS"

[ -r "$RUNDIR"/"$NAME".sh ] && . "$RUNDIR"/"$NAME".sh || echo "no machine specific variables for customizing VM in "$RUNDIR"/"$NAME".sh" >> /var/tmp/info.log


logger -p info -t i-tee "Creating VM: $NAME from Template: ${TEMPLATE}"


if [ $(VBoxManage list vms | cut -f1 -d' '| tr -d '"'| grep "^$NAME$" ) ]
then
	echo "VM $NAME already exists"
else
	SNAPSHOT=$(vboxmanage snapshot "$TEMPLATE" list|grep '*'|grep template|awk '{print $2}')
	if [ -z "$SNAPSHOT" ]
	then
		echo "cloning $NAME using $TEMPLATE"
		 time VBoxManage clonevm "$TEMPLATE" --name "$NAME" --register
	else
	        echo "Cloning $NAME using $TEMPLATE and snapshot $SNAPSHOT"
		time VBoxManage clonevm  "$TEMPLATE" --snapshot "$SNAPSHOT" --options link --name "$NAME" --register
	fi


	USERNAME=${NAME##*-}
	GROUPNAME=${NAME:0:((${#NAME}-${#USERNAME})-1)}

	if [ -r "/var/labs/run/$TEMPLATE.sh" ]
	then
		. "/var/labs/run/$TEMPLATE.sh"

		curl -k -H 'Content-Type: application/json' -X DELETE -d '{"api_key":"'"$API_KEY_ADMIN"'", "lab":"'"$LAB_ID"'", "userName":"'"$USERNAME"'", "reset":false}' "$LAB_URI"
		USER_KEY=$(curl -k -H 'Content-Type: application/json' -X POST -d '{"api_key":"'"$API_KEY_ADMIN"'", "lab":"'"$LAB_ID"'", "fullname":"'"$FULLNAME"'", "username":"'"$USERNAME"'", "password":"'"$USER_PWD"'", "host":"'"$IT_HOSTNAME"'", "info":{"answer":"42"}}' "$LAB_URI" | cut -d'"' -f4 -)

		VBoxManage setextradata "$NAME" "VBoxInternal/Devices/pcbios/0/Config/DmiSystemSerial" "${LAB_ID}/${USER_KEY}"
	else
		VBoxManage setextradata "$NAME" "VBoxInternal/Devices/pcbios/0/Config/DmiSystemSerial" "System Serial"
	fi

	if [ "$?" -ne 0 ]
	then
		echo "Cloning VM $NAME failed from template $TEMPLATE failed"
		exit 1
	fi

	VBoxManage modifyvm "$NAME" --groups "/$GROUPNAME","/$USERNAME"

	PWDHASH=$(VBoxManage internalcommands passwordhash "$USER_PWD" | cut -f3 -d' ')
	VBoxManage setextradata "$NAME" "VBoxAuthSimple/users/$USERNAME" "$PWDHASH"
	# dmidecode -s bios-version
	VBoxManage setextradata "$NAME" "VBoxInternal/Devices/pcbios/0/Config/DmiBIOSVersion"       "$NAME"
	# dmidecode -s bios-release-date
	VBoxManage setextradata "$NAME" "VBoxInternal/Devices/pcbios/0/Config/DmiBIOSReleaseDate"   "$USERNAME"

	VBoxManage setextradata "$NAME" "VBoxInternal/Devices/pcbios/0/Config/DmiSystemProduct"     "System Product"
	VBoxManage setextradata "$NAME" "VBoxInternal/Devices/pcbios/0/Config/DmiSystemVersion"     "System Version"
	VBoxManage setextradata "$NAME" "VBoxInternal/Devices/pcbios/0/Config/DmiSystemSKU"         "System SKU"
	VBoxManage setextradata "$NAME" "VBoxInternal/Devices/pcbios/0/Config/DmiSystemFamily"      "System Family"
	VBoxManage setextradata "$NAME" "VBoxInternal/Devices/pcbios/0/Config/DmiSystemVendor"      "I-tee Distance Laboratory System"

	declare -f set_networks > /dev/null && set_networks

	RDP_PORT=${IP_ADDR##*.}
	VBoxManage modifyvm "$NAME" --vrdeport "10$RDP_PORT"

fi

VBoxManage startvm "$NAME" --type headless

if [ "$?" -ne 0 ]
then
	echo "Starting VM $NAME failed"
	exit 1
fi

echo "VM named: $NAME created"


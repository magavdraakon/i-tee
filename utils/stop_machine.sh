#!/bin/bash
if [ $# -ne 1 ]
then 
echo "anna masina nimi"

exit 1
fi

NAME=$1
VIRT_DIR="/var/lib/libvirt/images"
IMAGE=$VIRT_DIR/$NAME.img
XML=/etc/libvirt/qemu/$NAME.xml
echo "haltin virtuaalmasina $NAME"
#minna masinasse ssh-ga sisse, sudo -i ja halt
#virsh -c qemu:///system create $XML

echo "kustutan masina image"
#rm $IMAGE



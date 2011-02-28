#!/bin/bash
if [ $# -ne 1 ]
then 
echo "anna masina nimi"

exit 1
fi

NAME=$1

echo "pausin virtuaalmasina $NAME"
virsh -c qemu:///system suspend $NAME


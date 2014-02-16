#!/bin/bash
if [ $# -ne 1 ]
then 
echo "anna masina nimi"
exit 1
fi

NAME=$1


#TODO ensure that VM with that name exists
time VBoxManage controlvm $NAME poweroff 

time VBoxManage unregistervm $NAME --delete
echo "haltin virtuaalmasina $NAME"


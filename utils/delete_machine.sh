#!/bin/bash
if [ $# -ne 1 ]
then 
echo "Error: Machine name is missing!"
exit 1
fi

NAME=$1


#TODO ensure that VM with that name exists
time VBoxManage controlvm $NAME poweroff || logger -p warn -t i-tee filed to power off $NAME

time VBoxManage unregistervm $NAME --delete || logger -p err -t i-tee filed to unregister $NAME
echo "VM $NAME deleted."


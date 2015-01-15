#!/bin/bash
if [ $# -ne 1 ]
then 
echo "Error: Machine name is missing!"
exit 1
fi

NAME=$1


#TODO ensure that VM with that name exists
time VBoxManage controlvm $NAME poweroff || logger -p warn -t ITEE failed to power off $NAME

sleep 5

time VBoxManage unregistervm $NAME --delete || {
logger -p err -t ITEE failed to unregister $NAME
logger -p err -t ITEE $(pwd) $(ls -l $NAME)
sleep 5
time VBoxManage unregistervm $NAME --delete || logger -p err -t ITEE failed to unregister $NAME again
}

logger -p info -t i-tee VM $NAME deleted
echo "VM $NAME deleted."


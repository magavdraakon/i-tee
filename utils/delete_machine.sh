#!/bin/bash
if [ $# -ne 1 ]
then 
echo "Error: Machine name is missing!"
exit 1
fi

NAME=$1


#TODO ensure that VM with that name exists
time VBoxManage controlvm ${NAME} poweroff || logger -p warn -t ITEE failed to power off ${NAME}


time VBoxManage unregistervm $NAME --delete || {
logger -p err -t ITEE failed to unregister ${NAME}
#VBoxManage showvminfo ${NAME} --machinereadable|less
VM_DIR="$(echo "$(dirname "$(vboxmanage showvminfo ${NAME}| grep 'Config file:'|cut -d: -f2)")"|sed 's/^ *//')"

logger -p info -t i-tee VM ${NAME} from ${VM_DIR}
sleep 1
time VBoxManage unregistervm ${NAME} --delete || logger -p err -t ITEE failed to unregister ${NAME} again
}


echo "VM $NAME deleted."


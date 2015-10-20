#!/bin/bash
# Author Margus Ernits
# License MIT
# Script stops all machines

for i in $(VBoxManage list runningvms | cut -f1 -d' '| tr -d '"')
do
echo "Stopping $i"
VBoxManage controlvm $i acpipowerbutton
#VBoxManage setextradata $i

done
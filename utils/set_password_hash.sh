#!/bin/bash

[ $# -ne 2 ] && {
echo "Give hash as: $0 VBoxAuthSimple/users/USERNAME longlonghash"
exit 1
}

for i in $(VBoxManage list vms| cut -f1 -d' '| tr -d '"')
do
echo $i
echo "VBoxManage setextradata $i $1 $2"


done


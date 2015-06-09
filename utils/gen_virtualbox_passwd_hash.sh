#!/bin/bash
# Author Margus Ernits
# License MIT

read -p "Username:" USERNAME

echo -n "Password:"
read -s PASSWORD
echo

if [ ${#PASSWORD} -lt 9 ]
then
        echo "Give at least 9 characters"
        exit 1
fi


HASH=$(VBoxManage internalcommands passwordhash $PASSWORD | cut -f 3 -d' ')


echo "VBoxAuthSimple/users/$USERNAME" "$HASH"
#VBoxManage setextradata "$VM" "VBoxAuthSimple/users/$USERNAME" $HASH


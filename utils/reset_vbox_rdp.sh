#!/usr/bin/env bash


if [ $# -eq 1 ]
then
    echo "Resetting RDP connections to $1"
    vboxmanage controlvm $1 vrde off
    vboxmanage controlvm $1 vrde on
else
    echo "Use $0 VM_NAME to reser RDP connections to VM_NAME"
    exit 1
fi
#!/bin/bash

VIRT_DIR="/var/lib/libvirt/images"
XML_DIR="/etc/libvirt/qemu"

echo "passenger works under $USER in "

#genereerida neile kasutatavad käsud kasutusõiguste tagamiseks
#näiteks : chown $KASUTAJA $DIR jne
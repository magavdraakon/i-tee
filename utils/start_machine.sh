#!/bin/bash
if [ $# -ne 5 ]
then 
echo "anna viis argumenti (mac IP template name passwd)"

exit 1
fi

MAC=$1
IP_ADDR=$2
TEMPLATE=$3
NAME=$4
PWD=$5
VIRT_DIR="/var/lib/libvirt/images"
IMAGE=$VIRT_DIR/$NAME.img
XML=/etc/libvirt/qemu/$NAME.xml

echo "tekitan virtuaalmasina $NAME template-ist $TEMPLATE Mac aadressiga $MAC"
#luua TEMPLATE põhjal koopia IMAGE
echo "alustan kopeerimist"
cp $TEMPLATE $IMAGE
chgrp libvirtd $IMAGE
#chown libvirt-qemu:kvm $IMAGE 
echo "masin kopeeritud"

cat > $XML << LOPP
<domain type='kvm'>
  <name>$NAME</name>
  <uuid>$(uuid)</uuid>
  <memory>524288</memory>
  <currentMemory>524288</currentMemory>
  <vcpu>1</vcpu>
  <os>
    <type machine='pc-0.12' arch='x86_64'>hvm</type>
    <boot dev='hd'/>
  </os>
  <features>
    <acpi/>
    <apic/>
    <pae/>
  </features>
  <clock offset='utc'/>
  <on_poweroff>destroy</on_poweroff>
  <on_reboot>restart</on_reboot>
  <on_crash>restart</on_crash>
  <devices>
    <emulator>/usr/bin/kvm</emulator>
    <disk device='disk' type='file'>
      <driver name='qemu' type='qcow2'/>
      <source file='$IMAGE'/>
      <target bus='virtio' dev='vda'/>
      <address bus='0x00' domain='0x0000' type='pci' function='0x0' slot='0x05'/>
    </disk>
    <disk device='cdrom' type='block'>
      <driver name='qemu' type='raw'/>
      <target bus='ide' dev='hdc'/>
      <readonly/>
      <address bus='1' type='drive' unit='0' controller='0'/>
    </disk>
    <controller type='ide' index='0'>
      <address bus='0x00' domain='0x0000' type='pci' function='0x1' slot='0x01'/>
    </controller>
    <interface type='bridge'>
      <source bridge='br0'/>
      <mac address='$MAC'/>
    </interface>
    <serial type='pty'>
      <target port='0'/>
    </serial>
    <console type='pty'>
      <target port='0' type='serial'/>
    </console>
    <input bus='ps2' type='mouse'/>
    <graphics port='-1' type='vnc' autoport='yes'/>
    <sound model='ac97'>
      <address bus='0x00' domain='0x0000' type='pci' function='0x0' slot='0x04'/>
    </sound>
    <video>
      <model type='cirrus' heads='1' vram='9216'/>
      <address bus='0x00' domain='0x0000' type='pci' function='0x0' slot='0x02'/>
    </video>
    <memballoon model='virtio'>
      <address bus='0x00' domain='0x0000' type='pci' function='0x0' slot='0x06'/>
    </memballoon>
  </devices>
</domain>
LOPP

virsh -c qemu:///system create $XML
for try in $(seq 1 20); do
  ping -c1 $IP_ADDR
  if [ $? -eq 0]; then
    break
  else
    echo "Ootan...$try"
  fi
done
echo "masin loodud"


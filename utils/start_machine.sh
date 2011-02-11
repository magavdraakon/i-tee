#!/bin/bash
if [ $# -ne 2 ]
then 
echo "anna kaks argumenti"

exit 1
fi

MAC=$1
TEMPLATE=$2

echo "tekitan virtuaalmasina template-ist $TEMPLATE Mac aadressiga $MAC"

cat > masin.xml << LOPP
<domain type='kvm'>
  <name>test</name>
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
      <driver name='qemu' type='raw'/>
      <source file='/var/lib/libvirt/images/test-1.img'/>
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
    <interface type='network'>
      <mac address='$MAC'/>
      <source network='default'/>
      <target dev='vnet1'/>
      <model type='virtio'/>
      <address bus='0x00' domain='0x0000' type='pci' function='0x0' slot='0x03'/>
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


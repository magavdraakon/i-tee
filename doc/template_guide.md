#Linux guest template guide

##Needed programs

acpid (needed for virsh shutdown):

    sudo apt-get install acpid

Ruby for virtual machine feedback

    sudo apt-get install ruby

Openssh server for ssh connections

    sudo apt-get install ssh
    curl http://elab.itcollege.ee/itcollege_ssh.pub >> /root/.ssh/authorized_keys2

Shellinabox AJAX console for web based logins

    wget http://shellinabox.googlecode.com/files/shellinabox_2.10-1_amd64.deb
    dpkg -i shellinabox_2.10-1_amd64.deb

##Needed settings 

##Progress feedback script

The virtual machine can give feedback to the web inferface using a simple protocol

    curl --insecure https://elab.itcollege.ee/set_progress?ip=<ip>&progress=<progress '_' for break>
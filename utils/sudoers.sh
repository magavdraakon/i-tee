#!/bin/bash

cat >> /etc/sudoers.d/sudo-vm <<EOF
www-data ALL=(vbox) NOPASSWD: /var/www/railsapps/i-tee/utils/start_machine.sh
www-data ALL=(vbox) NOPASSWD: /var/www/railsapps/i-tee/utils/stop_machine.sh
www-data ALL=(vbox) NOPASSWD: /var/www/railsapps/i-tee/utils/resume_machine.sh
www-data ALL=(vbox) NOPASSWD: /var/www/railsapps/i-tee/utils/pause_machine.sh
www-data ALL=(vbox) NOPASSWD: /usr/bin/VBoxManage

EOF


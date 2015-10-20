#!/usr/bin/env bash
find /var/labs -name '*.vbox' -print0 | while read -d $'\0' file; do  vboxmanage registervm   "$file"; done

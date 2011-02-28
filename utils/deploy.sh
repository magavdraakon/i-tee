#!/bin/bash
cd /var/www/railsapps/i-tee
git pull
if [ $? -eq 0 ]
  then
  rake db:migrate RAILS_ENV='production'
  touch /var/www/railsapps/i-tee/tmp/restart.txt
else
  echo "Git error, try updating manually"
  exit 1
fi
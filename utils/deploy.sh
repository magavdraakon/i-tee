#!/bin/bash
cd /var/www/railsapps/i-tee
git pull
if [ $? -eq 0 ]; then
  echo "migrating database"
  rake db:migrate RAILS_ENV='production'
  echo "restarting rails app"
  touch /var/www/railsapps/i-tee/tmp/restart.txt
else
  echo "Git error, try updating manually"
  exit 1
fi
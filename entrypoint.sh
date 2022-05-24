#!/bin/bash

echo "Generating config..."
envsubst < /usr/local/lsws/conf/httpd_config.conf.tmpl > /usr/local/lsws/conf/httpd_config.conf
envsubst < /usr/local/lsws/conf/vhosts/docker/vhconf.conf.tmpl > /usr/local/lsws/conf/vhosts/docker/vhconf.conf

set -e
if [ -z "$(ls -A -- "/usr/local/lsws/conf/")" ]; then
    cp -R /usr/local/lsws/.conf/* /usr/local/lsws/conf/
fi
if [ -z "$(ls -A -- "/usr/local/lsws/admin/conf/")" ]; then
    cp -R /usr/local/lsws/admin/.conf/* /usr/local/lsws/admin/conf/
fi
chown 999:999 /usr/local/lsws/conf -R
chown 999:999 /usr/local/lsws/conf -R
chown 999:1000 /usr/local/lsws/admin/conf -R

function stop()
{
    echo "Stopping litespeed service ...."
    /usr/local/lsws/bin/lswsctrl "stop"
    pkill "tail"
}

trap 'stop' SIGTERM

echo "Starting Services..."
service cron start &

function checkDirAndPermissions() {
USER=www-data
DIR=/var/www/vhosts/localhost/html/public_html
  # Return early if directory doesn't exist
  if [ ! -d "$DIR" ]; then
    return 1
  fi

  # directory exist check permissions
  # Get directory user and group details
  INFO=( $(stat -L -c "%U %G" "$DIR") )
  OWNER=${INFO[0]}
  GROUP=${INFO[1]}

  if [[ -d $DIR && $USER = $OWNER && $GROUP = $GROUP ]]; then
    return 0 # Pass
  fi

  return 1 # Fail
}

function rootDocAvailable() {
  until checkDirAndPermissions
  do
    sleep 5
    echo "Wordpress is not ready yet.."
  done

  echo "Wordpress installed correctly."
}

# rootDocAvailable

# Start the LiteSpeed
/usr/local/lsws/bin/lswsctrl start

tail -f /usr/local/lsws/logs/access.log -f /usr/local/lsws/logs/error.log
#!/usr/bin/env bash

chmod 777 /etc/default
chmod a+x -R /cron.sh /db_backup.sh
env >>/etc/default/locale
/usr/sbin/service cron start

DIRECTORY='/etc/cron.d/'

if [ "$(ls -A ${DIRECTORY})" = "" ]; then
  echo "${DIRECTORY} is empty"
else
  crontab $DIRECTORY/*
fi

if [ -f "$BACKUPDIRLOG" ]; then
  echo "$BACKUPDIRLOG was exist."
else
  echo "$BACKUPDIRLOG is not exist, now create it."
  touch $BACKUPDIRLOG
fi

tail -f $BACKUPDIRLOG

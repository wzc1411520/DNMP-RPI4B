FROM zengfa/mysql:8
MAINTAINER fatryst <fatryst@gmail.com>

ENV BACKUPDIRLOG /var/lib/mysql/backup.log

COPY cron.sh /cron.sh
COPY db_backup.sh /db_backup.sh
COPY db_backup.job /etc/cron.d/db_backup.job

RUN chmod a+x /cron.sh

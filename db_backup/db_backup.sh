#!/bin/bash
. /etc/profile
#At Sunday, we will backup the completed databases and the incresed binary log during Saturday to Sunday.
#In other weekdays, we only backup the increaing binary log at that day!
################################
#the globle variables for MySQL#
################################

BACKUPDIR='/data/db_backup/mysqlbackup'
BACKUPDIR_OLDER='/data/db_backup/mysqlbackup_older'
DB_PID='/run/mysqld/mysqld.pid'
DB_SOCK='/run/mysqld/mysqld.sock'
LOG_DIR='/data/log/mysql'
BINLOG_DIR='/var/lib/mysql'
EXPIRY_DAYS=15
DELETE_DAYS=60

#time variables for completed backup
FULL_BAKDAY='Sunday'
TODAY=$(date +%A)
DATE=$(date +%Y%m%d)

###########################
#time variables for binlog#
###########################
#liftcycle for saving binlog
DELETE_OLDLOG_TIME=$(date "-d $DELETE_DAYS day ago" +%Y%m%d%H%M%S)
#The start time point to backup binlog, the usage of mysqlbinlog is --start-datetime, --stop-datetime, time format is %Y%m%d%H%M%S, eg:20170502171054, time zones is  [start-datetime, stop-datetime)
#The date to start backup binlog is yesterday at this very moment!
START_BACKUPBINLOG_TIMEPOINT=$(date "-d 1 day ago" +"%Y-%m-%d %H:%M:%S")

#BINLOG_LIST=`cat /var/lib/mysql/mysql-bin.index`

#注意在my.cnf中配置binlog文件位置时需要使用绝对路径，一定想成好习惯，不要给别人挖坑！！
#####################举例########################
#[mysqld]
#log_bin = /var/lib/mysql/mysql-bin
#####################举例########################
BINLOG_INDEX='/var/lib/mysql/mysql-bin.index'

##############################################
#Judge the mysql process is running or not.  #
#mysql stop return 1, mysql running return 0.#
##############################################
function DB_RUN() {
  if test -a $DB_PID && test -a $DB_SOCK; then
    return 0
  else
    return 1
  fi
}
###################################################################################################
#Judge the bacup directory is exsit not.                                                          #
#If the mysqlbakup directory was exsited, there willed return 0.                                  #
# If there is no a mysqlbakup directory, the fuction will create the directory and return value 1.#
###################################################################################################
function BACKDIR_EXSIT() {
  if test -d $BACKUPDIR; then
    #        echo "$BACKUPDIR was exist."
    return 0
  else
    echo "$BACKUPDIR is not exist, now create it."
    mkdir -pv $BACKUPDIR
    return 1
  fi
}

function BACK_DATE_DIR_EXSIT() {
  if test -d $BACKUPDIR/$DATE; then
    #        echo "$BACKUPDIR was exist."
    return 0
  else
    echo "$BACKUPDIR/$DATE is not exist, now create it."
    mkdir -pv $BACKUPDIR/$DATE
    return 1
  fi
}

###################################################################################################
#Judge the binlog is configed or not.                                                          #
#If the mysqlbakup directory was exsited, there willed return 0.                                  #
# If there is no a mysqlbakup directory, the fuction will create the directory and return value 1.#
###################################################################################################
function BINLOG_EXSIT() {
  if test -f $BINLOG_INDEX; then
    #        echo "$BACKUPDIR was exist."
    return 0
  fi
}

###################################################
#The full backup for all Databases                #
#This function is use to backup the all databases.#
###################################################
function FULL_BAKUP() {
  echo "At $(date +%D\ %T): Starting full backup the MySQL DB ... "
  #    rm -fr $BACKUPDIR/db_fullbak_$DATE.sql  #for test !!
  mysqldump -h mysql --lock-all-tables --flush-logs --master-data=2 -uroot -p"$MYSQL_ROOT_PASSWORD" -A | gzip >$BACKUPDIR/db_fullbak_$DATE.sql.gz
  FULL_HEALTH=$(echo $?)
  if [[ $FULL_HEALTH == 0 ]]; then
    echo "At $(date +%D\ %T): MySQL DB incresed backup successfully"
  else
    echo "MySQL DB full backup failed!"
  fi
}

#python
# >>> with open('/var/lib/mysql/mysql-bin.index','r') as obj:
# ...    for i in obj:
# ...       print os.path.basename(i)
# ...
# mysql-bin.000006
# mysql-bin.000007
# mysql-bin.000008
# mysql-bin.000009
function INCREASE_BAKUP() {
  echo "At $(date +%D\ %T): Starting increased backup the MySQL DB ... "
  mysqladmin -h mysql -uroot -p"$MYSQL_ROOT_PASSWORD" flush-logs
  mysql -h mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -e "purge master logs before ${DELETE_OLDLOG_TIME}"
  BACK_DATE_DIR_EXSIT $BACKUPDIR/$DATE
  for i in $(cat $BINLOG_INDEX | awk -F'/' '{print $NF}'); do
    mysqlbinlog -h mysql -uroot -p"$MYSQL_ROOT_PASSWORD" --start-datetime="$START_BACKUPBINLOG_TIMEPOINT" $BINLOG_DIR/$i | gzip >>$BACKUPDIR/$DATE/daily_backup_file.sql.gz
  done
  cat $BINLOG_DIR/$i | gzip >$BACKUPDIR/$DATE/$i.gz
  # mysqlbinlog -uroot -p"$MYSQL_ROOT_PASSWORD"  --start-datetime="$START_BACKUPBINLOG_TIME" $BINLOG_DIR/mysql-bin.[0-9]* |gzip >> $BACKUPDIR/db_daily_$DATE.sql.gz
  INCREASE_HEALTH=$(echo $?)
  if [[ $INCREASE_HEALTH == 0 ]]; then
    echo "At $(date +%D\ %T): MySQL DB incresed backup successfully"
  else
    echo "MySQL DB incresed backup failed!"
  fi
}

function OLDER_BACKDIR_EXSIT() {
  if test -d $BACKUPDIR_OLDER; then
    #        echo "$BACKUPDIR_OLDER was exist."
    return 0
  else
    echo "$BACKUPDIR_OLDER is not exist, now create it."
    mkdir -pv $BACKUPDIR_OLDER
    #        return 1
  fi
}
function BAKUP_CLEANER() {
  #move the backuped file that created time out of $EXPIRY_DAYS days to the BACKUPDIR_OLDER directory
  returnkey=$(find $BACKUPDIR -name "*.sql.gz" -mtime +$EXPIRY_DAYS -exec ls -lh {} \;)
  returnkey_old=$(find $BACKUPDIR_OLDER -name "*.sql.gz" -mtime +$DELETE_DAYS -exec ls -lh {} \;)
  if [[ $returnkey != '' ]]; then

    echo "----------------------"
    echo "Moving the older backuped file out of $EXPIRY_DAYS days to $BACKUPDIR_OLDER."
    echo "The moved file list is:"
    find $BACKUPDIR -name "*.sql.gz" -mtime +$EXPIRY_DAYS -exec mv {} $BACKUPDIR_OLDER \;
    echo "-----------------------"
  elif [[ $returnkey_old != '' ]]; then
    #delete the backuped file that created time out of $DELETE_DAYS days from BACKUPDIR_OLDER directory.
    echo "Delete the older backuped file out of $DELETE_DAYS days from $BACKUPDIR_OLDER."
    echo "The deleted files list is:"
    find $BACKUPDIR_OLDER -name "*.sql.gz" -mtime +$DELETE_DAYS -exec rm -fr {} \;
  fi
}

####################################
#--------------main----------------#
####################################
function MAIN() {
  #  DB_RUN #Judge the process is run or not, if not run, the script will not bakup db
  #  Run_process=$(echo $?)
  #  echo $?
  #  if [[ $Run_process == 0 ]]; then
  BINLOG_EXSIT
  binlog_index=$(echo $?)
  if [[ $binlog_index == 0 ]]; then
    echo "**********START**********"
    echo $(date +"%y-%m-%d %H:%M:%S %A")
    echo "~~~~~~~~~~~~~~~~~~~~~~~"
    if [[ $TODAY == $FULL_BAKDAY ]]; then
      echo "Start completed bakup ..."
      INCREASE_BAKUP
      FULL_BAKUP #full backup to all DB
      BAKUP_CLEANER
    else
      echo "Start increaing bakup ..."
      INCREASE_BAKUP
    fi
    echo "~~~~~~~~~~~~~~~~~~~~~~~"
    echo $(date +"%y-%m-%d %H:%M:%S %A")
    echo "**********END**********"
  else
    echo "**********START**********"
    echo $(date +"%y-%m-%d %H:%M:%S %A")
    echo "~~~~~~~~~~~~~~~~~~~~~~~"
    echo "Sorry, MySQL binlog was not configed, please config the my.cnf firstly!"
    echo "~~~~~~~~~~~~~~~~~~~~~~~"
    echo $(date +"%y-%m-%d %H:%M:%S %A")
    echo "**********END**********"
  fi
  #  else
  #    echo "**********START**********"
  #    echo $(date +"%y-%m-%d %H:%M:%S %A")
  #    echo "~~~~~~~~~~~~~~~~~~~~~~~"
  #    echo "Sorry, MySQL was not running, the db could not be backuped!"
  #    echo "~~~~~~~~~~~~~~~~~~~~~~~"
  #    echo $(date +"%y-%m-%d %H:%M:%S %A")
  #    echo "**********END**********"
  #  fi
}
#starting runing

BACKDIR_EXSIT
OLDER_BACKDIR_EXSIT
MAIN >>$BINLOG_DIR/backup.log

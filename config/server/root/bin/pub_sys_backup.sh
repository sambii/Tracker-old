#!/bin/bash

umask 077
max_backup_keep=7

function do_pub_sys_backup () {
    backup_dir=$1
    backup_path=$2

    function trim_backups () {
      arch_files=(`ls -rt $backup_path`) #reverse list of files in an array
      count=${#arch_files[@]}
      if [ $count -gt $max_backup_keep ]
      then
        del_count=`expr $count - $max_backup_keep`
        del_count=`expr $del_count - 1` #normalize for zero based array
        for i in $(seq 0 $del_count)
        do
          rm $backup_path/${arch_files[$i]}
        done
      fi
    }

    date=`date '+%Y-%m-%d_%H_%M_%S'`
    backup_file=daily_pub_sys_$date.gz

    tar -czf $backup_path/$backup_file $backup_dir
    trim_backups
}

### EGYPT ENVIRONMENT ####
do_pub_sys_backup /web/parlo-tracker/stem-egypt/current/public/system /root/pub_sys_backups/StemEgypt

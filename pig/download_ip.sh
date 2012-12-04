#!/bin/sh
source /etc/profile
root=`dirname $0`
lastday=`date -d yesterday +%Y%m%d`
logfile=/usr/local/nginx/logs/2012/access_$lastday
output=$root/output/download_ip_$lastday
rm -rf $output
pig -x local -param out_dir=$output -param logfile=$logfile $root/download_ip.pig 

find $root/output -type f -mtime +6 -exec rm {} \;

#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
# Copyright(c) 2020 Liu, Changcheng <changcheng.liu@aliyun.com>

host=127.0.0.1
port=3306
user=root
passwd=@Passwd123

db_name=ceph_rwl
thread_count=1
db_table_num=1
db_size_per_table=5000000
# test time: 30 minutes
duration=1800
# report interval: 10 mintues
report_interval=600
# tps limitation
#  0: no limitation
tps_limitation=0

#print a log and then exit
function EXIT() {
    [ $# -ne 0 ] && [ "$1" != "" ] && printf "$1\n"
    exit 1
}

#create database
echo "**************Create Database*****************"
mysql -u$user -p$passwd -h $host -P $port -e "create database if not exists $db_name;"
[ $? -eq 0 ] || EXIT "Create database FAILED!"

echo "**************Prepare data********************"
# prepare data
sysbench --rand-type=uniform --db-driver=mysql --mysql-db=$db_name --mysql-host=$host --mysql-port=$port --mysql-user=$user --mysql-password=$passwd --tables=$db_table_num --table-size=$db_size_per_table /usr/share/sysbench/oltp_read_write.lua prepare
[ $? -eq 0 ] || EXIT "Prepare data FAILED!"

echo "*************Run test*************************"
# execute test
sysbench --rand-type=uniform --db-driver=mysql --mysql-db=$db_name --mysql-host=$host --mysql-port=$port --mysql-user=$user --mysql-password=$passwd --tables=$db_table_num --table-size=$db_size_per_table --report-interval=$report_interval --threads=$thread_count --rate=$tps_limitation --time=$duration --percentile=99 /usr/share/sysbench/oltp_read_write.lua --delete_inserts=2 run
[ $? -eq 0 ] || EXIT "Start benchmark FAILED!"

echo "************Clean env**************************"
# cleanup environment
sysbench --db-driver=mysql --mysql-db=$db_name --mysql-host=$host --mysql-port=$port --mysql-user=$user --mysql-password=$passwd --tables=$db_table_num --table-size=$db_size_per_table /usr/share/sysbench/oltp_read_write.lua cleanup
[ $? -eq 0 ] || EXIT "Cleanup FAILED!"

#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
# Copyright(c) 2020 Liu, Changcheng <changcheng.liu@aliyun.com>

vm_name=ubuntu_rwl
vm_username=rwl
username_password=passwd123

fio_remote_dir=/home/rwl/changcheng/cloudbench/test/fio/libaio
fio_script_name=rbd_vm_disk_70r_30w.fio

function get_vm_ip() {
local vm_name=$1
local vm_username=$2
local username_passwd=$3
expect -c "
    set timeout 10
    spawn virsh console ${vm_name}
    expect {
	\"Escape character\" {send \"\r\r\" ; exp_continue} 
	\"rwl login:\" {send \"${vm_username}\r\"; exp_continue}
	\"Password:\" {send \"${username_passwd}\r\";} 
	} 
	send \"ip addr\r\"
	send \"exit\r\"
	expect \"rwl login:\"
	send \"\"
	expect eof
    " | grep 'inet ' | grep 'brd' | sed -n -e 's,.*inet \(.*\)/[0-9]\+.*,\1,p'
}

function start_vm() {
local vm_name=$1
(virsh list --all | grep ${vm_name} | grep -q 'running') || sudo virsh start ${vm_name}
while true
do
virsh list --all | grep -q "${vm_name}.*running" && return
sleep 10
done
}

function shutdown_vm() {
local vm_name=$1
sudo virsh shutdown ${vm_name}
while true
do
virsh list --all | grep -q "${vm_name}.* shut off" && return
done
}

function wait_ceph_no_client_io() {
while true
do
sudo ceph -s | grep -q '^ *client: ' || return
sleep 10
done
}

function upload_file() {
local vm_name=$1
local vm_username=$2
local username_passwd=$3
local remote_dir=$4
local upload_file_name=$5

if [ -f $upload_file_name ]; then
local_file_md5sum=`md5sum ${upload_file_name} | cut -d ' ' -f 1`
else
echo "local file not exist, we assue the remote vm already has the file"
return
fi
echo "wait for vm shutdown"
shutdown_vm ${vm_name}
echo "vm shutdown"

echo "echo starting vm"
start_vm ${vm_name}
echo "vm running"
sleep 60
vm_ip=$(get_vm_ip $vm_name $vm_username $username_passwd)

sshpass -p ${username_passwd} ssh ${vm_username}@${vm_ip} "sudo mkdir -p ${remote_dir}"
while true
do
remote_file_md5sum=`sshpass -p ${username_passwd} ssh ${vm_username}@${vm_ip} "if [ -f ${remote_dir}/${upload_file_name} ]; then md5sum ${remote_dir}/${upload_file_name} | cut -d ' ' -f 1; fi"`
if [ $remote_file_md5sum != ${local_file_md5sum} ]; then
echo "uploading file"
sshpass -p ${username_passwd} scp ${upload_file_name} ${vm_username}@${vm_ip}:${remote_dir}
else
echo "file uploaded"
return
fi
done
}

upload_file ${vm_name} ${vm_username} ${username_password} ${fio_remote_dir} ${fio_script_name}

echo "wait for vm shutdown"
shutdown_vm ${vm_name}
echo "vm shutdown"

count=0
while true
do
count=$((count+1))
echo "WAIT ceph no io"
wait_ceph_no_client_io
echo "confirm ceph no io"

echo "echo starting vm"
start_vm ${vm_name}
echo "vm running"

sleep 60

vm_ip=$(get_vm_ip $vm_name $vm_username $username_password)

echo ${vm_ip}

echo "start fio test"
sshpass -p ${username_password} ssh ${vm_username}@${vm_ip} "sudo fio ${fio_remote_dir}/${fio_script_name}" | tee rwl_rand_70r_30w_${count}.log
echo "end fio test"

echo "wait for vm shutdown"
shutdown_vm ${vm_name}
echo "vm shutdown"
done

#!/bin/bash -x

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

#apt-get install -y virtualbox

VM='Syncloud-VM'
SSH_PORT=3333

VBoxManage controlvm $VM poweroff

VBoxManage unregistervm $VM --delete

rm -rf syncloud.vdi
rm -rf syncloud-test.vdi

VBoxManage convertdd syncloud-vbox.img syncloud.vdi --format VDI

cp syncloud.vdi syncloud-test.vdi

xz -0 syncloud.vdi -k
rm -rf $HOME/"VirtualBox VMs"/$VM

VBoxManage createvm --name $VM --ostype "Debian_64" --register

VBoxManage storagectl $VM --name "SATA Controller" --add sata --controller IntelAHCI

VBoxManage list hdds

ls -la

VBoxManage storageattach $VM --storagectl "SATA Controller" --port 0 --device 0 --type hdd --medium syncloud-test.vdi

VBoxManage modifyvm $VM --ioapic on

VBoxManage modifyvm $VM --boot1 dvd --boot2 disk --boot3 none --boot4 none

VBoxManage modifyvm $VM --memory 1024 --vram 128

VBoxManage modifyvm $VM --natpf1 "guestssh,tcp,,${SSH_PORT},,22"

VBoxHeadless --startvm $VM &


ATTEMPT=0
TOTAL_ATTEMPTS=10

ssh-keygen -f "/root/.ssh/known_hosts" -R [localhost]:${SSH_PORT}

sshpass -p syncloud ssh -o StrictHostKeyChecking=no -p ${SSH_PORT} root@localhost date

while test $? -gt 0
do
  sleep 1
  echo "Waiting for SSH ..."
  ATTEMPT=$((ATTEMPT +1))
  echo "attempt $ATTEMPT of $TOTAL_ATTEMPTS"
  if [[ $ATTEMPT -gt $TOTAL_ATTEMPTS ]]; then
    echo "unable to connect to vbox instance"
    exit 1
  fi
  sshpass -p syncloud ssh -o StrictHostKeyChecking=no -p ${SSH_PORT} root@localhost date
  
done

sshpass -p syncloud ssh -o StrictHostKeyChecking=no -p ${SSH_PORT} root@localhost journalctl

VBoxManage controlvm $VM poweroff

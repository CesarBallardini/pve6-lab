#!/usr/bin/env bash
# provision/instala-ceph-otros.sh

pvenode_hostname=$1

if [ "${pvenode_hostname}" = "pve1" ]
then
        exit 0
fi

# en pve2 y pve3
echo y | sudo pveceph install -version nautilus
sudo pveceph createmon

# crea OSD
sudo pveceph osd create /dev/sdb
sudo pveceph osd create /dev/sdc
sudo pveceph osd create /dev/sdd
sudo pveceph osd create /dev/sde

sudo pveceph mgr create
sudo pveceph mds create


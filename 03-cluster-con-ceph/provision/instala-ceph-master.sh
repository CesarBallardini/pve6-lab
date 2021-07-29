#!/usr/bin/env bash
# provision/instala-ceph-master.sh

pvenode_hostname=$1
pvenode_ceph_network=$2

if [ "${pvenode_hostname}" != "pve1" ]
then
	exit 0
fi

# en pve1
echo y | sudo pveceph install -version nautilus
sudo pveceph init --network "${pvenode_ceph_network}"
sudo pveceph createmon

# crea OSD
sudo pveceph osd create /dev/sdb
sudo pveceph osd create /dev/sdc
sudo pveceph osd create /dev/sdd
sudo pveceph osd create /dev/sde

# habilita el autoescaler de placement groups
sudo ceph mgr module enable pg_autoscaler

# crea pool
sudo pveceph pool create ceph-vm  --size 3 --min_size 2 --pg_num 64 --add_storages
sudo pveceph pool create ceph-ct  --size 3 --min_size 2 --pg_num 64 --add_storages
sudo pveceph pool create test     --size 3 --min_size 2 --pg_num 64 --add_storages


# RADOS benchmark (10s)
#sudo rados -p test bench 10 write --no-cleanup
#sudo rados -p test bench 10 seq

# create Metadata Server
sudo pveceph mds create



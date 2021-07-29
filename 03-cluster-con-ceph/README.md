# README - Cluster 3 nodos PVE con Ceph

Usamos la característica experimental (2021-07-26) para crear nuevos discos en las VMs:

```bash
export VAGRANT_EXPERIMENTAL="disks"

# creacion cluster PVE
time vagrant up pve{1,2,3}

# recien despues de tener armado el cluster PVE se agrega cluster Ceph
time vagrant provision pve1     --provision-with ceph_master
time vagrant provision pve{2,3} --provision-with ceph_node

```


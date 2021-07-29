#!/usr/bin/env bash
# provision/cluster-create.sh

pvenode_hostname=$1
CLUSTERNAME=$2

if [ "${pvenode_hostname}" = "pve1" ]
then
  sudo pvecm create "${CLUSTERNAME}"
  sudo pvecm status
fi

exit 0

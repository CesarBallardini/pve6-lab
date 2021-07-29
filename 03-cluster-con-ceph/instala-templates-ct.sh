#!/usr/bin/env bash

#STORAGE_POOL="ceph-ct" # ISO y templates CT no se pueden almacenar en ceph
STORAGE_POOL="local"

ct_templates() {
  sudo pveam update

  sudo pveam download "${STORAGE_POOL}" debian-10-standard_10.7-1_amd64.tar.gz
  sudo pveam download "${STORAGE_POOL}" ubuntu-20.04-standard_20.04-1_amd64.tar.gz
  sudo pveam download "${STORAGE_POOL}" alpine-3.13-default_20210419_amd64.tar.xz

}


##
# main
#

#ct_templates

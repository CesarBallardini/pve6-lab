#!/usr/bin/env bash

ct_templates() {
  sudo pveam update

  sudo pveam download local debian-10-standard_10.7-1_amd64.tar.gz
  sudo pveam download local ubuntu-20.04-standard_20.04-1_amd64.tar.gz
  sudo pveam download local alpine-3.13-default_20210419_amd64.tar.xz

}


##
# main
#

ct_templates

#!/usr/bin/env bash

export DEBIAN_FRONTEND=noninteractive
export APT_LISTCHANGES_FRONTEND=none
export APT_OPTIONS=' -y --allow-downgrades --allow-remove-essential --allow-change-held-packages -o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confold '
export APT_OPTIONS_NEW=' -y --allow-downgrades --allow-remove-essential --allow-change-held-packages -o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confnew '

# solamente despues de haber reiniciado con el kernel pve:
sudo -E apt-get remove --purge linux-image-amd64 'linux-image-4.19*'  ${APT_OPTIONS_NEW}
sudo rm -rf /lib/modules/4.19*

sudo update-grub
sudo apt-get autoremove -y

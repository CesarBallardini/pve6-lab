#!/usr/bin/env bash

pve_username=$1
pve_password=$2


export DEBIAN_FRONTEND=noninteractive
export APT_LISTCHANGES_FRONTEND=none
export APT_OPTIONS=' -y --allow-downgrades --allow-remove-essential --allow-change-held-packages -o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confold '
export APT_OPTIONS_NEW=' -y --allow-downgrades --allow-remove-essential --allow-change-held-packages -o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confnew '

sudo apt-get install sshpass unzip ${APT_OPTIONS}

instala_terraform() {
  VERSION=1.0.2
  TF_ZIP_FILENAME=terraform_${VERSION}_linux_amd64.zip
  TF_URL=https://releases.hashicorp.com/terraform/${VERSION}/${TF_ZIP_FILENAME}

  cd /tmp
  [ -f ${TF_ZIP_FILENAME} ] || wget ${TF_URL}
  [ -f terraform ] || unzip ${TF_ZIP_FILENAME}
  [ -f /usr/local/bin/terraform ] || sudo mv terraform /usr/local/bin/
  sudo chmod a+rx /usr/local/bin/terraform

  terraform version

  grep "complete -C /usr/local/bin/terraform terraform" ~/.bashrc >/dev/null || terraform -install-autocomplete

}

configura_proxmox() {
  cd /vagrant/tf/

  cat > .env <<!EOF
export PM_USER="${pve_username}"
export PM_PASS="${pve_password}"
!EOF

  terraform init
}

instala_terraform
configura_proxmox

# genera claves SSH para acceder a los CT y VM
[ -d /vagrant/tf/ssh-keys ] || mkdir /vagrant/tf/ssh-keys
[ -f ~/.ssh/id_rsa-tf.pub ] || ( ssh-keygen -b 2048 -t rsa -f /vagrant/tf/ssh-keys/id_rsa-tf -q -N "" ; chmod og-rwx /vagrant/tf/ssh-keys/id_rsa-tf )


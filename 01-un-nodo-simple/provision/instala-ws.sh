#!/usr/bin/env bash

pvenode_hostname=pve1
pvenode_domain=infra.ballardini.com.ar
pvenode_ip_address=192.168.33.11


export DEBIAN_FRONTEND=noninteractive
export APT_LISTCHANGES_FRONTEND=none
export APT_OPTIONS=' -y --allow-downgrades --allow-remove-essential --allow-change-held-packages -o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confold '
export APT_OPTIONS_NEW=' -y --allow-downgrades --allow-remove-essential --allow-change-held-packages -o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confnew '

sudo apt-get install sshpass unzip ${APT_OPTIONS}

instala_terraform() {
  wget https://releases.hashicorp.com/terraform/1.0.2/terraform_1.0.2_linux_amd64.zip
  unzip terraform_1.0.2_linux_amd64.zip 
  sudo mv terraform /usr/local/bin/
  sudo chmod a+rx /usr/local/bin/terraform

  terraform version

  terraform -install-autocomplete

}

configura_proxmox() {
  export PM_PASS="admin"
  export PM_USER="root@pam"

  terraform init
}

#!/usr/bin/env bash

##
# VMIDs:
#
# 9001-9999: templates de VMs
# 5001-9000: VMs
# 1001-5000: CTs

vm_template_ubuntu_2004() {

  VMID=$1
  STORAGE_POOL="local"
  PVE_NODE_NAME=pve1
  VM_NAME=ubuntu-20.04-template

  URL_BASE=https://cloud-images.ubuntu.com/focal/current
  FILENAME=focal-server-cloudimg-amd64

  FILENAME_DIR=/vagrant/tmp/
  # se debe renombrar el archivo para que el reconocimiento de formato funcione, ver:
  # https://bugzilla.proxmox.com/show_bug.cgi?id=2469#c2
  LOCAL_FILENAME="${FILENAME_DIR}/${FILENAME}.qcow2"
  URL="${URL_BASE}/${FILENAME}.img"

  if [ ! -f "${LOCAL_FILENAME}" ] 
  then
    wget "${URL}" -O "${LOCAL_FILENAME}" -o /dev/null

    # https://manpages.ubuntu.com/manpages//focal/man1/virt-customize.1.html
    # ver USERS AND PASSWORDS en https://manpages.ubuntu.com/manpages//focal/man1/virt-builder.1.html
    sudo virt-customize -a "${LOCAL_FILENAME}" --root-password password:ubuntu

    # no esta creada en la imagen cloud la cuenta ubuntu
    #sudo virt-customize -a "${LOCAL_FILENAME}" --password ubuntu:password:ubuntu # USUARIO:password:CONTRASE

    sudo virt-customize -a "${LOCAL_FILENAME}" --install qemu-guest-agent
    sudo virt-customize -a "${LOCAL_FILENAME}" --run-command "sed -i 's/.*PasswordAuthentication.*/PasswordAuthentication yes/g' /etc/ssh/sshd_config"
    # instalo algunos paquetes utiles en el template
    sudo virt-customize -a "${LOCAL_FILENAME}" --run-command "DEBIAN_FRONTEND=noninteractive apt-get install -y bmon screen ntpdate vim mc locate locales-all iotop atop htop curl wget libpam-systemd python3-pip python3-dev ifenslave vlan sysstat snmpd sudo lynx rsync nfs-common tcpdump strace darkstat"

  fi

  sudo qm show ${VMID} > /dev/null
  if [ $? -eq 0 ]
  then
    BUSCA="/${VMID}/base-${VMID}-disk"
    # FIXME: hay que hacerlo recursivo en el .parent
    VM_A_DESTRUIR=$( sudo pvesh get /nodes/${PVE_NODE_NAME}/storage/${STORAGE_POOL}/content/ --output-format json-pretty \
            | jq -r '.[] | select(.parent | type=="string") | select(.parent | contains("'"${BUSCA}"'")) | .vmid' )

    if [ -n "${VM_A_DESTRUIR}" ]
    then
      sudo qm stop $VM_A_DESTRUIR ; sudo qm destroy $VM_A_DESTRUIR
    fi
    sudo qm destroy $VMID
  fi

  sudo qm create "${VMID}" --memory 2048 --net0 virtio,bridge=vmbr0
  sudo qm importdisk "${VMID}" "${LOCAL_FILENAME}" "${STORAGE_POOL}"
  sudo qm rescan
  sudo qm set "${VMID}" --scsihw virtio-scsi-pci --scsi0 "${STORAGE_POOL}":${VMID}/vm-${VMID}-disk-0.raw
  sudo qm resize ${VMID} scsi0 +5G
  
  sudo qm set "${VMID}" --agent enabled=1,fstrim_cloned_disks=1
  sudo qm set "${VMID}" --name $VM_NAME

  # cloudinit config
  sudo qm set "${VMID}" --ide2 "${STORAGE_POOL}":cloudinit
  sudo qm set "${VMID}" --boot c --bootdisk scsi0
  #sudo qm set "${VMID}" --serial0 socket --vga serial0
  sudo qm set "${VMID}" --serial0 socket --vga qxl # para que funcione el SPICE
  sudo qm template "${VMID}"

}


vm_template_debian_10() {

  VMID=$1
  STORAGE_POOL="local"
  PVE_NODE_NAME=pve1
  VM_NAME=debian-10-template

  URL_BASE=https://cdimage.debian.org/cdimage/openstack/current-10
  FILENAME=debian-10-openstack-amd64.qcow2

  FILENAME_DIR=/vagrant/tmp/
  LOCAL_FILENAME="${FILENAME_DIR}/${FILENAME}"
  URL="${URL_BASE}/${FILENAME}"

  if [ ! -f "${LOCAL_FILENAME}" ]
  then
    wget "${URL}" -O "${LOCAL_FILENAME}" -o /dev/null

    sudo virt-customize -a "${LOCAL_FILENAME}" --install qemu-guest-agent
    sudo virt-customize -a "${LOCAL_FILENAME}" --run-command "sed -i 's/.*PasswordAuthentication.*/PasswordAuthentication yes/g' /etc/ssh/sshd_config"
    # instalo algunos paquetes utiles en el template
    sudo virt-customize -a "${LOCAL_FILENAME}" --run-command "DEBIAN_FRONTEND=noninteractive apt-get install -y bmon screen ntpdate vim mc locate locales-all iotop atop htop curl wget libpam-systemd python3-pip python3-dev ifenslave vlan sysstat snmpd sudo lynx rsync nfs-common tcpdump strace darkstat"
  fi


  sudo qm show ${VMID} > /dev/null
  if [ $? -eq 0 ] 
  then
    BUSCA="/${VMID}/base-${VMID}-disk"
    # FIXME: hay que hacerlo recursivo en el .parent
    VM_A_DESTRUIR=$( sudo pvesh get /nodes/${PVE_NODE_NAME}/storage/${STORAGE_POOL}/content/ --output-format json-pretty \
	    | jq -r '.[] | select(.parent | type=="string") | select(.parent | contains("'"${BUSCA}"'")) | .vmid' )

    if [ -n "${VM_A_DESTRUIR}" ]
    then
      sudo qm stop $VM_A_DESTRUIR ; sudo qm destroy $VM_A_DESTRUIR
    fi
    sudo qm destroy $VMID 
  fi

  sudo qm create "${VMID}" -name "${VM_NAME}" \
	  -memory 1024 \
	  -net0 virtio,bridge=vmbr0 \
	  -cores 1 -sockets 1 -cpu cputype=kvm64 \
	  -description "Debian 10 cloud image" \
	  -kvm 1 -numa 1

  sudo qm importdisk "${VMID}" "${LOCAL_FILENAME}" "${STORAGE_POOL}" --format qcow2
  sudo qm rescan
  sudo qm set "${VMID}" -scsihw virtio-scsi-pci -virtio0 ${STORAGE_POOL}:${VMID}/vm-${VMID}-disk-0.qcow2
  sudo qm set "${VMID}" -serial0 socket
  sudo qm set "${VMID}" -boot c -bootdisk virtio0
  sudo qm set "${VMID}" -agent 1
  sudo qm set "${VMID}" -hotplug disk,network,usb,memory,cpu
  sudo qm set "${VMID}" -vcpus 1
  sudo qm set "${VMID}" -vga qxl
  sudo qm set "${VMID}" -name "${VM_NAME}"
  sudo qm set "${VMID}" -ide2 ${STORAGE_POOL}:cloudinit
  sudo qm set "${VMID}" -sshkey /root/pve/pub_keys/pub_key.pub
  sudo qm set "${VMID}" --cipassword "debian"  # passwd del usuario default que es `debian`
  #sudo qm set "${VMID}" --ipconfig0 ip=192.168.44.2/24,gw=192.168.44.1
  sudo qm template "${VMID}"

}



lanza_vm_desde_template() {
  TEMPLATE_ID=$1
  VMID=$2
  VM_NAME=$3
  shift ; shift ; shift

  sudo qm show ${VMID} > /dev/null
  [ $? -eq 0 ] && ( sudo qm stop $VMID && sudo qm destroy $VMID )

  sudo qm clone "${TEMPLATE_ID}" "${VMID}" --name "${VM_NAME}"

  sudo qm set "${VMID}" -sshkey /root/pve/pub_keys/pub_key.pub
  while [ $# -gt 0 ]
  do
    echo "["$1"]"
    sudo qm set "${VMID}" $1
    shift
  done

  sudo qm start "${VMID}"
}


##
# main
#

sudo apt-get install libguestfs-tools -y

# directorio para las imagenes de disco cloud descargadas de internet
[ -d /vagrant/tmp ] || mkdir /vagrant/tmp

sudo mkdir -p /root/pve/pub_keys/
sudo [ -f /root/pve/pub_keys/pub_key ] || ( sudo ssh-keygen -q -N ""  -b 4096 -f /root/pve/pub_keys/pub_key ; sudo chmod g-r /root/pve/pub_keys/pub_key )

#vm_template_ubuntu_2004 9001
#vm_template_debian_10 9002

#lanza_vm_desde_template 9002 5002 deb10-vm5002 "--ipconfig0 ip=192.168.44.2/24,gw=192.168.44.1"
#lanza_vm_desde_template 9001 5005 ubu20-vm5005 "--ipconfig0 ip=192.168.44.5/24,gw=192.168.44.1"

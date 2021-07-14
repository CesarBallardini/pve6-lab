# README - Un solo nodo PVE con un bridge conectado a la red *host_only*

# Descripción general

En `pve1`

* La interfaz `eth0` es la interfaz NAT estándar de Virtualbox y sirve para que el nodo aceda a Internet.
* La interfaz `eth1` tiene dirección IP 192.168.33.11 en la red de hipervisores. `eth1` tiene la dirección IP 192.168.33.11; el host le asocia la interfaz `vboxnet0` con dirección IP 192.168.33.1
* La interfaz `eth2` está asociada al bridge Linux `vmbr0`. `vmbr0` tiene la dirección IP 192.168.44.11; el host le asocia la interfaz `vboxnet1` con dirección IP 192.168.44.1


En `ws` la interfaz `eth1` tiene dirección IP 192.168.33.10 en la red de hipervisores, para conectarse a 192.168.33.11 de `pve1`. El ruteo en el host permite acceder a las VM y CT desde `ws`.


Se pueden crear CT y VM desde `ws` (workstation) mediante terraform allí instalado.

Las unidades así creadas pueden tener dirección IP en la red 192.168.44.0/24, que se puede acceder desde `ws` y desde el host de Virtualbox.

FIXME: Las unidades no tienen acceso a Internet.


# Requisitos previos

Deben existir y tener las direcciones de IP correctas las interfaces en el host:

```bash
sudo VBoxManage hostonlyif create
sudo VBoxManage hostonlyif ipconfig vboxnet0 --ip 192.168.33.1

sudo VBoxManage hostonlyif create
sudo VBoxManage hostonlyif ipconfig vboxnet1 --ip 192.168.44.1

vboxmanage list  hostonlyifs

```

# Uso

* clonar el repo

```bash
git clone https://github.com/CesarBallardini/pve6-lab
cd pve6-lab/01-un-nodo-simple/
```

* levantar la VM `pve1`

```bash
time vagrant up pve1
```

* Configurar el bridge `vmbr0`. Usar la Web UI 
  * https://pve1.infra.ballardini.com.ar:8006/
  * credenciales: `root / admin`
  * Datacenter -> pve1
    * System -> Network -> Create
      * Linux Bridge
        * Name: vmbr0
        * IPv4/CIDR: 192.168.44.11/24
        * Gateway (IPv4): 192.168.44.1
        * Bridge ports: eth2
        * Comment: Red de Servicio
      * Click en Create.
    * Click Apply Configuration -> Do you want to apply pending network changes? -> Click Yes


* conectar mediante SSH a `pve1` ( `vagrant ssh pve1` ) y descargar las imágenes y templates:

```bash

# templates para CT:
source /vagrant/instala-templates-ct.sh
ct_templates


# template de ejemplo con Debian 10 (Buster) y Ubuntu 20.04 (Focal):
# Esto puede llevar cierto tiempo en descargar imagenes cloud de varios cientos de MB
source /vagrant/instala-templates-vm.sh
vm_template_ubuntu_2004 9001
vm_template_debian_10 9002

```

* crear VMs con Debian10 y Ubuntu20.04

```bash
# lanza_vm_desde_template ID_TEMPLATE ID_VM HOSTNAME CONFIGURACIONES_ADICIONALES

lanza_vm_desde_template 9002 5002 deb10-vm5002 "--ipconfig0 ip=192.168.44.2/24,gw=192.168.44.1"
lanza_vm_desde_template 9001 5005 ubu20-vm5005 "--ipconfig0 ip=192.168.44.5/24,gw=192.168.44.1"
```

* conectar con las VMs

```bash

ssh-keygen -f ~/.ssh/known_hosts -R "192.168.44.2"
ssh-keyscan 192.168.44.2 >> ~/.ssh/known_hosts
sshpass -p debian ssh debian@192.168.44.2
sudo ssh -i /root/pve/pub_keys/pub_key debian@192.168.44.2 # deb10-vm5002

ssh-keygen -f ~/.ssh/known_hosts -R "192.168.44.5"
ssh-keyscan 192.168.44.5 >> ~/.ssh/known_hosts
sshpass -p ubuntu ssh ubuntu@192.168.44.5
sudo ssh -i /root/pve/pub_keys/pub_key   root@192.168.44.5 # ubu20-vm5005


```


---
# Uso de Terraform

* en `pve1` instalar el *hookscript* para permitir que root ingrese por SSH

En `/var/lib/vz/snippets/tf-deb10.hookscript.sh` poner:

```bash
#!/usr/bin/env bash
vmid=$1
phase=$2

# Este script corre en pve1 en las diferentes fases del CT que lo tiene como hookscript

case "${phase}" in
  'pre-start' )
    # First phase 'pre-start' will be executed before the guest
    # ist started. Exiting with a code != 0 will abort the start

    #echo "${vmid} is starting, doing preparations."

    # echo "preparations failed, aborting."
    # exit(1)
  ;;

  'post-start')
    # Second phase 'post-start' will be executed after the guest
    # successfully started.

    pct exec ${vmid} -- sed -E -i 's/^#?PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
    pct exec ${vmid} -- systemctl restart ssh

    echo "$vmid started successfully."
  ;;

  'pre-stop')
    # Third phase 'pre-stop' will be executed before stopping the guest
    # via the API. Will not be executed if the guest is stopped from
    # within e.g., with a 'poweroff'

    #echo "$vmid will be stopped."
  ;;

  'post-stop')
    # Last phase 'post-stop' will be executed after the guest stopped.
    # This should even be executed in case the guest crashes or stopped
    # unexpectedly.

    #echo "$vmid stopped. Doing cleanup."
  ;;

  *)
    echo "got unknown phase [${phase}]"
    exit 1
  ;;
esac

```


y luego hacerlo ejecutable:

```bash
sudo chmod a+rx /var/lib/vz/snippets/tf-deb10.hookscript.sh
```

NOTA: esto se podría ahcer con Ansible desde `ws` accionando sobre `pve1`

* levantar la VM `ws`

```bash
time vagrant up ws 
```

* conectar mediante SSH a `ws` ( `vagrant ssh ws` ) y crear la infraestructura mediante Terraform:

```bash
cd /vagrant/tf/
source .env

# crea la infra
time terraform apply 

# muestra la infra conocida por tf
terraform state list

# destruye la infra
time terraform destroy

```

* conectar mediante SSH

```bash
touch ~/.ssh/known_hosts

# tf-deb10-ct4998
ssh-keygen -f ~/.ssh/known_hosts -R "192.168.44.98"
ssh-keyscan 192.168.44.98 >> ~/.ssh/known_hosts
sshpass -p debian ssh root@192.168.44.98

# tf-deb10-vm8999
ssh-keygen -f ~/.ssh/known_hosts -R "192.168.44.99"
ssh-keyscan 192.168.44.99 >> ~/.ssh/known_hosts
sshpass -p debian ssh debian@192.168.44.99

```


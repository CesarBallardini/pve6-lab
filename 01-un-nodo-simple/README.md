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
/vagrant/instala-templates-ct.sh

# template de ejemplo con Debian 10 (Buster) y crear una VM de ejemplo:
/vagrant/instala-templates-vm.sh
```



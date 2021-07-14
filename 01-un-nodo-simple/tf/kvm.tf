data "template_file" "ssh_pub_key" {
  #template = "${file("/home/vagrant/.ssh/id_rsa-tf.pub")}"
  template = "${file("/vagrant/tf/ssh-keys/id_rsa-tf.pub")}"
}


resource "proxmox_vm_qemu" "tf_deb10_vm8999" {
    name = "tf-deb10-vm8999"
    desc = "A test for using terraform and cloudinit"
    vmid = "5004"
    onboot = "true"

    # Node name has to be the same name as within the cluster
    # this might not include the FQDN
    target_node = "pve1"

    # The destination resource pool for the new VM
    #pool = "pool0"

    # The template name to clone this vm from
    clone = "debian-10-template"

    # Activate QEMU agent for this VM
    agent = 1

    os_type = "cloud-init"
    cores = 2
    sockets = 1
    vcpus = 0
    cpu = "host"
    memory = 1024
    #scsihw = "lsi"

    # Setup the disk
    disk {
        size = "2G"
        type = "virtio"
        storage = "local"
        #storage_type = "rbd"
        #iothread = 1
        #ssd = 1
        #discard = "on"
    }

    # Setup the network interface and assign a vlan tag: 256
    network {
        model = "virtio"
        bridge = "vmbr0"
        #tag = 256
    }

    # Setup the ip address using cloud-init.
    # Keep in mind to use the CIDR notation for the ip.
    ipconfig0 = "ip=192.168.44.99/24,gw=192.168.44.11"

    sshkeys = "${data.template_file.ssh_pub_key.rendered}"

#    sshkeys = <<EOF
#    ssh-rsa 9182739187293817293817293871== user@pc
#    EOF
}

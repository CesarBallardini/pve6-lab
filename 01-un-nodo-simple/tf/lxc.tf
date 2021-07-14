resource "proxmox_lxc" "tf_deb10_ct4998" {

  hostname = "tf-deb10-ct4998"
  password     = "debian" # para la cuenta root en el CT
  vmid = "1003"
  start = "true"
  onboot = "true"
  tags = "lxc,tf,debian10,pve1" 

  target_node  = "pve1"
  #pool = "terraform"
  ostemplate   = "local:vztmpl/debian-10-standard_10.7-1_amd64.tar.gz"
  unprivileged = true

  features {
    nesting = true
  }

  // Terraform will crash without rootfs defined
  rootfs {
    storage = "local"
    size    = "3G"
  }

  network {
    name   = "eth0"
    bridge = "vmbr0"
    ip     = "192.168.44.98/24"
    gw = "192.168.44.1"
  }

  # https://pve.proxmox.com/pve-docs/pve-admin-guide.html#_hookscripts_2
  # https://registry.terraform.io/providers/Telmate/proxmox/latest/docs/resources/lxc#hookscript
  # el script debe estar en pve1 en /var/lib/vz/snippets/tf-deb10.hookscript.sh
  hookscript = "local:snippets/tf-deb10.hookscript.sh"
}

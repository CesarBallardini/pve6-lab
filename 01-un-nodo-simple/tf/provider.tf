terraform {

  required_version = ">= 0.14"

  required_providers {
    proxmox = {
      source = "telmate/proxmox"
      version = "2.7.3"
    }
  }
}

provider "proxmox" {
  pm_api_url = "https://pve1.infra.ballardini.com.ar:8006/api2/json"
  pm_tls_insecure = "true"

}

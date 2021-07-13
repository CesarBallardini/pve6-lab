#!/usr/bin/env bash


pvenode_hostname=pve1
pvenode_domain=infra.ballardini.com.ar
pvenode_ip_address=192.168.33.11

export DEBIAN_FRONTEND=noninteractive
export APT_LISTCHANGES_FRONTEND=none
export APT_OPTIONS=' -y --allow-downgrades --allow-remove-essential --allow-change-held-packages -o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confold '
export APT_OPTIONS_NEW=' -y --allow-downgrades --allow-remove-essential --allow-change-held-packages -o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confnew '



instala_requisitos_previos() {

  sudo -E apt-get install debconf-utils wget libguestfs-tools jq sshpass ${APT_OPTIONS}

}


asegura_etc_hosts() {

  cat - | sudo tee /etc/hosts <<!EOF
127.0.0.1       localhost.localdomain localhost
${pvenode_ip_address}    ${pvenode_hostname}.${pvenode_domain}  ${pvenode_hostname}

# The following lines are desirable for IPv6 capable hosts
::1     localhost ip6-localhost ip6-loopback
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
!EOF

  # verifica:
  [ "$( hostname --ip-address )" = "${pvenode_ip_address}" ] || ( echo "falla la direccion IP" ; exit 1 )
  [ "$( hostname --short      )" = "${pvenode_hostname}"   ] || ( echo "falla el hostname"     ; exit 1 )
  [ "$( hostname --domain     )" = "${pvenode_domain}"     ] || ( echo "falla el domain"       ; exit 1 )

}

configura_fuente_pve() {

  echo "deb [arch=amd64] http://download.proxmox.com/debian/pve $( lsb_release -cs ) pve-no-subscription" | sudo tee /etc/apt/sources.list.d/pve-install-repo.list > /dev/null

  # FIXME: el nombre del archivo de clave GPG delata la versión de PVE, parametrizarlo
  wget http://download.proxmox.com/debian/proxmox-ve-release-6.x.gpg -O /tmp/proxmox-ve-release-6.x.gpg -o /dev/null
  sudo mv /tmp/proxmox-ve-release-6.x.gpg /etc/apt/trusted.gpg.d/proxmox-ve-release-6.x.gpg
  sudo chmod +r /etc/apt/trusted.gpg.d/proxmox-ve-release-6.x.gpg

  sudo -E apt-get update -qq
}


pre_configura_grub_pc() {

  while read config_line 
  do
    sudo debconf-set-selections  <<< "$config_line"
  done <<!EOF
grub-pc	grub-pc/install_devices_empty	boolean	false
grub-pc	grub2/update_nvram	boolean	true
grub-pc	grub2/kfreebsd_cmdline_default	string	quiet
grub-pc	grub-pc/hidden_timeout	boolean	false
grub-pc	grub-pc/install_devices_disks_changed	multiselect	
grub-pc	grub2/kfreebsd_cmdline	string	
grub-pc	grub-pc/kopt_extracted	boolean	false
grub-pc	grub2/force_efi_extra_removable	boolean	false
grub-pc	grub-pc/timeout	string	5
grub-pc	grub-pc/mixed_legacy_and_grub2	boolean	true
grub-pc	grub-pc/install_devices	multiselect	/dev/sda
grub-pc	grub-pc/chainload_from_menu.lst	boolean	true
grub-pc	grub-pc/install_devices_failed	boolean	false
grub-pc	grub2/linux_cmdline	string	consoleblank=0
grub-pc	grub2/linux_cmdline_default	string	net.ifnames=0 biosdevname=0
grub-pc	grub-pc/install_devices_failed_upgrade	boolean	true
grub-pc	grub-pc/postrm_purge_boot_grub	boolean	false
!EOF

}


pre_configura_samba() {

# no tomar config WINS desde DHCP
  while read config_line 
  do
    sudo debconf-set-selections  <<< "$config_line"
  done <<!EOF
samba-common	samba-common/workgroup	string	WORKGROUP
samba-common	samba-common/dhcp	boolean	false
samba-common	samba-common/do_debconf	boolean	true
!EOF

}


pre_configura_postfix() {

  # local site
  while read config_line 
  do
    sudo debconf-set-selections  <<< "$config_line"
  done <<!EOF
postfix	postfix/mailbox_limit	string	0
postfix	postfix/procmail	boolean	false
postfix	postfix/sqlite_warning	boolean	
postfix	postfix/rfc1035_violation	boolean	false
postfix	postfix/dynamicmaps_conversion_warning	boolean	
postfix	postfix/mailname	string	pve1
postfix	postfix/mydomain_warning	boolean	
postfix	postfix/destinations	string	pve1, $myhostname, pve1.infra.ballardini.com.ar, localhost.infra.ballardini.com.ar, localhost
postfix	postfix/relayhost	string	
postfix	postfix/main_mailer_type	select	Local only
postfix	postfix/protocols	select	all
postfix	postfix/relay_restrictions_warning	boolean	
postfix	postfix/compat_conversion_warning	boolean	true
postfix	postfix/mynetworks	string	127.0.0.0/8 [::ffff:127.0.0.0]/104 [::1]/128
postfix	postfix/root_address	string	
postfix	postfix/retry_upgrade_warning	boolean	
postfix	postfix/main_cf_conversion_warning	boolean	true
postfix	postfix/recipient_delim	string	+
postfix	postfix/tlsmgr_upgrade_warning	boolean	
postfix	postfix/lmtp_retired_warning	boolean	true
postfix	postfix/newaliases	boolean	false
postfix	postfix/kernel_version_warning	boolean	
postfix	postfix/chattr	boolean	false
!EOF
}



elimina_popup_subscription() {
  sudo sed -i.bak 's/NotFound/Active/g' /usr/share/perl5/PVE/API2/Subscription.pm
  sudo systemctl restart pveproxy.service
}


##
# main
#

sudo -E apt-get full-upgrade     ${APT_OPTIONS_NEW}
sudo -E apt-get remove os-prober ${APT_OPTIONS}


asegura_etc_hosts

instala_requisitos_previos
configura_fuente_pve
pre_configura_grub_pc
pre_configura_samba 
pre_configura_postfix



sudo debconf-set-selections <<< "grub grub/update_grub_changeprompt_threeway select install_new"
sudo -E apt-get -o Dpkg::Options::="--force-confnew" -yy dist-upgrade -yq

sudo -E apt-get install proxmox-ve postfix open-iscsi -q ${APT_OPTIONS_NEW}

# falla la instalacion y hay que reiniciar el servicio antes de continuarla con --fix-broken
sudo systemctl restart pvestatd.service
sudo systemctl status pvestatd.service
sudo -E apt-get install --fix-broken -q ${APT_OPTIONS_NEW}

# los headers los voy a necesitar cuando reinicie con el nuevo kernel y haya que instalar el soporte para Virtualbox
sudo -E apt-get install pve-headers-$( dpkg -l  | sed -n 's/ii[ ]*pve-kernel-\(.*-pve\).*/\1/p' ) ${APT_OPTIONS}

sudo update-grub

# elimino el fuente enterprise de paquetes
sudo rm -f /etc/apt/sources.list.d/pve-enterprise.list
sudo -E apt-get update -qq

# pone la passwd de cuenta root@pam
echo root:admin | sudo chpasswd

elimina_popup_subscription

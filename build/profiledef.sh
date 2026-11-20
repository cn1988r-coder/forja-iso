#!/usr/bin/env bash
iso_name="venom"
iso_label="VENOM_$(date +%Y%m)"
iso_publisher="VENOM OS"
iso_application="VENOM OS Live"
iso_version="$(date +%Y.%m.%d)"
install_dir="arch"
buildmodes=('iso')
bootmodes=('bios.syslinux' 'uefi-iso.grub')
arch="x86_64"
pacman_conf="pacman.conf"
airootfs_image_type="squashfs"
file_permissions=(
 ["/etc/shadow"]="0:0:400"
 ["/root"]="0:0:750"
 ["/root/.automated_script.sh"]="0:0:755"
)

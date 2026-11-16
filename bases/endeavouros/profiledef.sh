#!/usr/bin/env bash
# Fundação inicial Forja OS sobre componentes EndeavourOS.
# Este perfil ainda não está completo nem validado para build.

iso_name="forja-os"
iso_label="FORJA_OS_$(date +%Y%m)"
iso_publisher="Forja OS"
iso_application="Forja OS"
iso_version="$(date --date="@${SOURCE_DATE_EPOCH:-$(date +%s)}" +%Y.%m.%d)"
install_dir="arch"
buildmodes=('iso')
bootmodes=('bios.syslinux' 'uefi.grub')
arch="x86_64"
pacman_conf="pacman.conf"
airootfs_image_type="squashfs"
airootfs_image_tool_options=('-comp' 'zstd' '-b' '1M')
file_permissions=(
  ["/etc/shadow"]="0:0:400"
)

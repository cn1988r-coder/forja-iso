#!/usr/bin/env bash
# Forja OS XFCE profile for the EndeavourOS modified Archiso framework.
# Keep boot modes and image layout aligned with the upstream EndeavourOS profile.
iso_name="ForjaOS_XFCE"
iso_label="FORJA_$(date +%Y%m)"
iso_publisher="Forja OS"
iso_application="Forja OS XFCE Live/Install"
iso_version="$(date --date="@${SOURCE_DATE_EPOCH:-$(date +%s)}" +%Y.%m.%d)"
install_dir="arch"
buildmodes=('iso')
bootmodes=('bios.syslinux' 'uefi.systemd-boot')
arch="x86_64"
pacman_conf="pacman.conf"
airootfs_image_type="squashfs"
airootfs_image_tool_options=('-comp' 'xz' '-Xbcj' 'x86' '-b' '1M' '-Xdict-size' '1M')
work_dir="work"
out_dir="out"

file_permissions=(
  ["/etc/shadow"]="0:0:400"
  ["/etc/gshadow"]="0:0:400"
  ["/root"]="0:0:750"
  ["/etc/sudoers.d"]="0:0:750"
)

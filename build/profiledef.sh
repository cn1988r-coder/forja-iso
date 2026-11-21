#!/usr/bin/env bash
# shellcheck disable=SC2034
iso_name="venom"
iso_label="VENOM_$(date --date="@${SOURCE_DATE_EPOCH:-$(date +%s)}" +%Y%m)"
iso_publisher="VENOM OS"
iso_application="VENOM OS Live"
iso_version="$(date --date="@${SOURCE_DATE_EPOCH:-$(date +%s)}" +%Y.%m.%d)"
install_dir="arch"
bootmodes=('bios.syslinux' 'uefi.grub')
arch="x86_64"
packages="packages.x86_64"
pacman_conf="pacman.conf"
airootfs_image_type="squashfs"
airootfs_image_tool_options=('-comp' 'xz' '-Xbcj' 'x86' '-b' '1M' '-Xdict-size' '1M')
kernel_params_x86_64="script=/root/venom-live-setup console=tty0 console=ttyS0,115200n8 systemd.log_target=console systemd.log_level=info"
file_permissions=(
 ["/etc/shadow"]="0:0:400"
 ["/root"]="0:0:750"
 ["/root/.automated_script.sh"]="0:0:755"
 ["/root/venom-live-setup"]="0:0:755"
)

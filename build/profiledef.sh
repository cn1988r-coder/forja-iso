#!/usr/bin/env bash
# shellcheck disable=SC2034
iso_name="venom"
iso_label="VENOM_$(date --date="@${SOURCE_DATE_EPOCH:-$(date +%s)}" +%Y%m)"
iso_publisher="VENOM OS"
iso_application="VENOM OS Installer"
iso_version="$(date --date="@${SOURCE_DATE_EPOCH:-$(date +%s)}" +%Y.%m.%d)"
install_dir="arch"
bootmodes=('bios.syslinux' 'uefi.grub')
arch="x86_64"
packages="packages.x86_64"
pacman_conf="pacman.conf"
airootfs_image_type="squashfs"
airootfs_image_tool_options=('-comp' 'zstd' '-Xcompression-level' '15' '-b' '1M')
# Inicializacao direta do instalador TUI na tty1. Nenhum desktop Live.
kernel_params_x86_64="console=tty0 console=ttyS0,115200n8 systemd.log_target=console systemd.log_level=info systemd.firstboot=headless systemd.unit=multi-user.target"
declare -A file_permissions=(
 ["/etc/shadow"]="0:0:400"
 ["/root"]="0:0:750"
 ["/usr/lib/venom/install-system"]="0:0:755"
)

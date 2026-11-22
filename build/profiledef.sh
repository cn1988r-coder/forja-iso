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
# Zstandard reduz a pressão de memória em relação ao xz -9e no runner.
airootfs_image_tool_options=('-comp' 'zstd' '-Xcompression-level' '15' '-b' '1M')
# Inicializa diretamente no console multi-user; o getty@tty1 inicia o TUI.
kernel_params_x86_64="console=tty0 console=ttyS0,115200n8 systemd.log_target=console systemd.log_level=info systemd.firstboot=headless systemd.unit=multi-user.target"
declare -A file_permissions=(
 ["/etc/shadow"]="0:0:400"
 ["/root"]="0:0:750"
)

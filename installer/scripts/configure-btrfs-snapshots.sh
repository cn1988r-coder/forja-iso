#!/usr/bin/env bash
# Configure the installed VENOM Btrfs/Timeshift/GRUB snapshot stack.
# Usage: configure-btrfs-snapshots ROOT_DIR ROOT_BLOCK_DEVICE
set -Eeuo pipefail

ROOT_DIR=${1:?Uso: $0 ROOT_DIR ROOT_BLOCK_DEVICE}
ROOT_DEVICE=${2:?Uso: $0 ROOT_DIR ROOT_BLOCK_DEVICE}

fail() { printf '[VENOM snapshots] ERRO: %s\\n' "$*" >&2; exit 1; }
[[ $EUID -eq 0 ]] || fail "execute como root"
[[ -d "$ROOT_DIR/etc" && -d "$ROOT_DIR/boot" ]] || fail "ROOT_DIR não parece ser a raiz do sistema instalado"
[[ -b "$ROOT_DEVICE" ]] || fail "dispositivo raiz inválido: $ROOT_DEVICE"
command -v blkid >/dev/null || fail "blkid não encontrado"
command -v findmnt >/dev/null || fail "findmnt não encontrado"

FSTYPE=$(blkid -s TYPE -o value -- "$ROOT_DEVICE")
UUID=$(blkid -s UUID -o value -- "$ROOT_DEVICE")
[[ "$FSTYPE" == btrfs ]] || fail "a partição raiz precisa ser Btrfs"
[[ "$UUID" =~ ^[A-Fa-f0-9-]+$ ]] || fail "UUID Btrfs inválido"

mkdir -p "$ROOT_DIR/etc" "$ROOT_DIR/etc/timeshift" "$ROOT_DIR/etc/mkinitcpio.conf.d"
FSTAB="$ROOT_DIR/etc/fstab"
touch "$FSTAB"
cp -a "$FSTAB" "$FSTAB.venom-backup"

# Preserve ESP, swap and other mount entries; replace only / and /home.
awk '$2 != "/" && $2 != "/home" { print }' "$FSTAB.venom-backup" > "$FSTAB"
cat >> "$FSTAB" <<EOF
UUID=$UUID / btrfs rw,noatime,compress=zstd:1,ssd,space_cache=v2,subvol=@ 0 0
UUID=$UUID /home btrfs rw,noatime,compress=zstd:1,ssd,space_cache=v2,subvol=@home 0 0
EOF
if grep -Eq '(^|,)subvolid=' "$FSTAB"; then
  fail "fstab contém subvolid fixo; instalação cancelada"
fi

cat > "$ROOT_DIR/etc/mkinitcpio.conf.d/venom-btrfs.conf" <<'EOF'
# Btrfs kernel module and repair utility in the initramfs.
MODULES+=(btrfs)
BINARIES+=(btrfs)
EOF

cat > "$ROOT_DIR/etc/timeshift/timeshift.json" <<EOF
{
  "backup_device_uuid": "$UUID",
  "parent_device_uuid": "$UUID",
  "do_first_run": "false",
  "btrfs_mode": "true",
  "include_btrfs_home_for_backup": "false",
  "include_btrfs_home_for_restore": "false",
  "schedule_monthly": "false",
  "schedule_weekly": "false",
  "schedule_daily": "false",
  "schedule_hourly": "false",
  "schedule_boot": "false",
  "count_monthly": "2",
  "count_weekly": "3",
  "count_daily": "5",
  "count_hourly": "6",
  "count_boot": "5",
  "date_format": "%Y-%m-%d %H:%M:%S",
  "exclude": [],
  "exclude-apps": []
}
EOF

# The systemd unit shipped by grub-btrfs retains its upstream hardening.
install -d "$ROOT_DIR/etc/systemd/system/grub-btrfsd.service.d"
cat > "$ROOT_DIR/etc/systemd/system/grub-btrfsd.service.d/override.conf" <<'EOF'
[Service]
ExecStart=
ExecStart=/usr/bin/grub-btrfsd --syslog --timeshift-auto
EOF

# Configure the installed target only. This script does not touch block devices.
if [[ -x "$ROOT_DIR/usr/bin/arch-chroot" ]]; then
  CHROOT=(arch-chroot "$ROOT_DIR")
elif command -v systemd-nspawn >/dev/null; then
  CHROOT=(systemd-nspawn -D "$ROOT_DIR")
else
  fail "arch-chroot ou systemd-nspawn não disponível"
fi

"${CHROOT[@]}" mkinitcpio -P
"${CHROOT[@]}" grub-mkconfig -o /boot/grub/grub.cfg
"${CHROOT[@]}" systemctl enable cronie.service
"${CHROOT[@]}" systemctl enable grub-btrfsd.service

printf '[VENOM snapshots] Configuração aplicada. Ainda é obrigatório validar boot e restauração em VM BIOS e UEFI.\\n'

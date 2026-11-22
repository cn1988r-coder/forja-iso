#!/usr/bin/env bash
# Run inside the installer's post-install stage, after Btrfs subvolumes,
# fstab, kernel and GRUB installation have been completed.
# Usage: configure-btrfs-snapshots.sh ROOT_DIR ROOT_BLOCK_DEVICE
set -Eeuo pipefail

ROOT_DIR=${1:?Uso: $0 ROOT_DIR ROOT_BLOCK_DEVICE}
ROOT_DEVICE=${2:?Uso: $0 ROOT_DIR ROOT_BLOCK_DEVICE}
fail() { printf '[VENOM snapshots] ERRO: %s\n' "$*" >&2; exit 1; }

[[ $EUID -eq 0 ]] || fail "execute como root"
[[ -d "$ROOT_DIR/etc" && -d "$ROOT_DIR/boot" ]] || fail "raiz instalada inválida"
[[ -b "$ROOT_DEVICE" ]] || fail "dispositivo raiz inválido"
command -v blkid >/dev/null || fail "blkid não encontrado"
command -v arch-chroot >/dev/null || fail "arch-chroot não encontrado no ambiente instalador"

FSTYPE=$(blkid -s TYPE -o value -- "$ROOT_DEVICE")
UUID=$(blkid -s UUID -o value -- "$ROOT_DEVICE")
[[ "$FSTYPE" == btrfs ]] || fail "a partição raiz precisa ser Btrfs"
[[ "$UUID" =~ ^[A-Fa-f0-9-]+$ ]] || fail "UUID Btrfs inválido"

FSTAB="$ROOT_DIR/etc/fstab"
[[ -f "$FSTAB" ]] || fail "fstab não foi criado pelo instalador"
grep -Eq '[[:space:]]/[[:space:]].*subvol=@([,[:space:]]|$)' "$FSTAB" || fail "fstab não monta @ em /"
grep -Eq '[[:space:]]/home[[:space:]].*subvol=@home([,[:space:]]|$)' "$FSTAB" || fail "fstab não monta @home em /home"
if grep -Eq '(^|,)subvolid=' "$FSTAB"; then
  fail "fstab contém subvolid fixo, incompatível com restauração de snapshots"
fi

install -d "$ROOT_DIR/etc/mkinitcpio.conf.d" "$ROOT_DIR/etc/timeshift"
cat > "$ROOT_DIR/etc/mkinitcpio.conf.d/venom-btrfs.conf" <<'EOF'
# Btrfs module and repair utility in the initramfs.
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

install -d "$ROOT_DIR/etc/systemd/system/grub-btrfsd.service.d"
cat > "$ROOT_DIR/etc/systemd/system/grub-btrfsd.service.d/override.conf" <<'EOF'
[Service]
ExecStart=
ExecStart=/usr/bin/grub-btrfsd --syslog --timeshift-auto
EOF

# This runs only inside the selected target root. It does not partition,
# format, mount, or write to any block device.
arch-chroot "$ROOT_DIR" mkinitcpio -P
arch-chroot "$ROOT_DIR" grub-mkconfig -o /boot/grub/grub.cfg
arch-chroot "$ROOT_DIR" systemctl enable cronie.service
arch-chroot "$ROOT_DIR" systemctl enable grub-btrfsd.service

printf '[VENOM snapshots] Configuração aplicada. Validar boot, snapshots e restauração em VMs BIOS/UEFI antes de liberar.\n'

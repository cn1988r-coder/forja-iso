#!/usr/bin/env bash
# VENOM OS / Arch Linux
# Integra Btrfs + Timeshift + grub-btrfs no sistema instalado.
# Executar pelo backend do instalador após montar ROOT_DIR, instalar o kernel
# e instalar o GRUB no modo de firmware correspondente (BIOS ou UEFI).
# Uso interno do instalador: setup-arch-btrfs-timeshift-grub.sh ROOT_DIR ROOT_DEVICE
set -Eeuo pipefail

ROOT_DIR=${1:?ROOT_DIR obrigatório}
ROOT_DEVICE=${2:?ROOT_DEVICE obrigatório}
fail() { printf '[VENOM BTRFS] ERRO: %s\n' "$*" >&2; exit 1; }

[[ $EUID -eq 0 ]] || fail "o backend precisa executar como root"
[[ -d "$ROOT_DIR/etc" && -d "$ROOT_DIR/boot" ]] || fail "raiz de destino inválida"
[[ -b "$ROOT_DEVICE" ]] || fail "dispositivo raiz inválido"
for bin in blkid arch-chroot findmnt; do
  command -v "$bin" >/dev/null 2>&1 || fail "$bin não encontrado no ambiente live"
done

FSTYPE=$(blkid -s TYPE -o value -- "$ROOT_DEVICE")
UUID=$(blkid -s UUID -o value -- "$ROOT_DEVICE")
[[ "$FSTYPE" == btrfs ]] || fail "a partição raiz selecionada não é Btrfs"
[[ "$UUID" =~ ^[A-Fa-f0-9-]+$ ]] || fail "UUID Btrfs inválido"

FSTAB="$ROOT_DIR/etc/fstab"
[[ -f "$FSTAB" ]] || fail "fstab ausente; o backend deve gerar o fstab antes"
grep -Eq '[[:space:]]/[[:space:]].*subvol=/?@([,[:space:]]|$)' "$FSTAB" ||
  fail "fstab precisa montar o subvolume @ em /"
grep -Eq '[[:space:]]/home[[:space:]].*subvol=/?@home([,[:space:]]|$)' "$FSTAB" ||
  fail "fstab precisa montar @home em /home"
if grep -Eq '(^|,)subvolid=' "$FSTAB"; then
  fail "fstab não pode fixar subvolid; isso impede a troca correta do snapshot raiz"
fi
# /boot deve ficar dentro de @ para kernel e initramfs acompanharem o snapshot.
if awk '$2 == "/boot" { found=1 } END { exit !found }' "$FSTAB"; then
  fail "/boot não pode ser partição/subvolume separado; mantenha-o dentro de @"
fi

install -d "$ROOT_DIR/etc/mkinitcpio.conf.d" "$ROOT_DIR/etc/timeshift" \
  "$ROOT_DIR/etc/systemd/system/grub-btrfsd.service.d"

# Instala os componentes nativos da base Arch no sistema de destino.
arch-chroot "$ROOT_DIR" pacman -S --needed --noconfirm \
  btrfs-progs timeshift grub-btrfs inotify-tools cronie

cat > "$ROOT_DIR/etc/mkinitcpio.conf.d/venom-btrfs.conf" <<'EOF'
# Suporte Btrfs no initramfs da VENOM OS.
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
  "schedule_weekly": "true",
  "schedule_daily": "true",
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

# Preserva o unit fornecido pelo pacote e ativa a descoberta de snapshots Timeshift.
cat > "$ROOT_DIR/etc/systemd/system/grub-btrfsd.service.d/override.conf" <<'EOF'
[Service]
ExecStart=
ExecStart=/usr/bin/grub-btrfsd --syslog --timeshift-auto
EOF

arch-chroot "$ROOT_DIR" mkinitcpio -P
arch-chroot "$ROOT_DIR" grub-mkconfig -o /boot/grub/grub.cfg
arch-chroot "$ROOT_DIR" systemctl enable cronie.service
arch-chroot "$ROOT_DIR" systemctl enable grub-btrfsd.service

printf '[VENOM BTRFS] Timeshift, grub-btrfs e GRUB configurados no sistema de destino.\n'

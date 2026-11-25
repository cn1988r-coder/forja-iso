#!/usr/bin/env bash
# VENOM OS: integração BTRFS + Timeshift + GRUB.
# Executar pelo instalador, como root, após montar ROOT_DIR, criar os
# subvolumes @ e @home, gerar fstab e instalar kernel/GRUB.
# Uso: setup-arch-btrfs-timeshift-grub.sh ROOT_DIR ROOT_DEVICE
set -Eeuo pipefail

ROOT_DIR=${1:?Uso: $0 ROOT_DIR ROOT_DEVICE}
ROOT_DEVICE=${2:?Uso: $0 ROOT_DIR ROOT_DEVICE}
fail() { printf '[VENOM BTRFS] ERRO: %s\n' "$*" >&2; exit 1; }

[[ $EUID -eq 0 ]] || fail "execute como root"
[[ -d "$ROOT_DIR/etc" && -d "$ROOT_DIR/boot" ]] || fail "raiz de destino inválida"
[[ -b "$ROOT_DEVICE" ]] || fail "dispositivo BTRFS da raiz inválido"
for bin in blkid arch-chroot; do
  command -v "$bin" >/dev/null 2>&1 || fail "$bin não encontrado no ambiente live"
done

FSTYPE=$(blkid -s TYPE -o value -- "$ROOT_DEVICE")
UUID=$(blkid -s UUID -o value -- "$ROOT_DEVICE")
[[ "$FSTYPE" == btrfs ]] || fail "a partição raiz selecionada não é BTRFS"
[[ "$UUID" =~ ^[A-Fa-f0-9-]+$ ]] || fail "UUID BTRFS inválido"

FSTAB="$ROOT_DIR/etc/fstab"
[[ -f "$FSTAB" ]] || fail "fstab ausente"
grep -Eq '[[:space:]]/[[:space:]].*subvol=/?@([,[:space:]]|$)' "$FSTAB" ||
  fail "fstab precisa montar o subvolume @ em /"
grep -Eq '[[:space:]]/home[[:space:]].*subvol=/?@home([,[:space:]]|$)' "$FSTAB" ||
  fail "fstab precisa montar @home em /home"
if grep -Eq '(^|,)subvolid=' "$FSTAB"; then
  fail "fstab não pode fixar subvolid; isso impede a restauração correta do snapshot raiz"
fi
if awk '$2 == "/boot" { found=1 } END { exit !found }' "$FSTAB"; then
  fail "/boot deve permanecer dentro do subvolume @ para acompanhar os snapshots"
fi

# Firefox, Pamac e Timeshift são conferidos no conjunto de pacotes da VENOM OS.
# Firefox e Timeshift vêm dos repositórios Arch; Pamac é fornecido pelo AUR.
for pkg in firefox timeshift; do
  arch-chroot "$ROOT_DIR" pacman -Q "$pkg" >/dev/null 2>&1 ||
    fail "$pkg não está instalado no sistema de destino"
done
arch-chroot "$ROOT_DIR" pacman -Q pamac-aur >/dev/null 2>&1 ||
  fail "pamac-aur não está instalado no sistema de destino"

# Pacotes oficiais necessários à integração BTRFS/Timeshift.
arch-chroot "$ROOT_DIR" pacman -S --needed --noconfirm btrfs-progs timeshift inotify-tools cronie
# grub-btrfs é AUR e deve ter sido incluído na etapa de pacotes AUR da imagem.
arch-chroot "$ROOT_DIR" pacman -Q grub-btrfs >/dev/null 2>&1 ||
  fail "grub-btrfs não está instalado; confira build/aur-packages.x86_64"

install -d "$ROOT_DIR/etc/mkinitcpio.conf.d" "$ROOT_DIR/etc/timeshift" \
  "$ROOT_DIR/etc/systemd/system/grub-btrfsd.service.d"

cat > "$ROOT_DIR/etc/mkinitcpio.conf.d/venom-btrfs.conf" <<'EOF'
# Suporte BTRFS no initramfs da VENOM OS.
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

# Ativa a descoberta dos snapshots Timeshift pelo GRUB.
cat > "$ROOT_DIR/etc/systemd/system/grub-btrfsd.service.d/override.conf" <<'EOF'
[Service]
ExecStart=
ExecStart=/usr/bin/grub-btrfsd --syslog --timeshift-auto
EOF

arch-chroot "$ROOT_DIR" mkinitcpio -P
arch-chroot "$ROOT_DIR" grub-mkconfig -o /boot/grub/grub.cfg
arch-chroot "$ROOT_DIR" systemctl enable cronie.service
arch-chroot "$ROOT_DIR" systemctl enable grub-btrfsd.service

printf '[VENOM BTRFS] Integração configurada: Timeshift + BTRFS + GRUB.\n'
printf '[VENOM BTRFS] Firefox, Pamac e Timeshift conferidos no sistema instalado.\n'

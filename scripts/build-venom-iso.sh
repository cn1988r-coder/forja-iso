#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK="${ROOT}/work"
PROFILE="${WORK}/venom-profile"
OUTPUT="${WORK}/out"
ARCHISO_RELENG="/usr/share/archiso/configs/releng"

log() { printf '\n[VENOM] %s\n' "$*"; }
die() { printf '\n[ERRO] %s\n' "$*" >&2; exit 1; }

[[ "$(uname -m)" == x86_64 ]] || die "A ISO atual é destinada a x86_64."
[[ $EUID -ne 0 ]] || die "Execute como usuário normal; sudo será usado somente no mkarchiso."
command -v git >/dev/null || die "git não encontrado."
command -v magick >/dev/null || die "ImageMagick não encontrado."
command -v mkarchiso >/dev/null || die "Instale o pacote oficial archiso."
[[ -d "$ARCHISO_RELENG" ]] || die "Perfil releng do Archiso não encontrado em $ARCHISO_RELENG."

log "Preparando perfil VENOM a partir do perfil oficial Archiso"
rm -rf "$PROFILE"
mkdir -p "$PROFILE" "$OUTPUT"
cp -a "$ARCHISO_RELENG/." "$PROFILE/"
cp -a "$ROOT/build/archiso/." "$PROFILE/"

log "Montando a seleção de pacotes exclusivamente dos manifestos VENOM/Arch"
{
  cat "$ROOT/build/packages.arch"
  cat "$ROOT/build/packages.mate"
  printf '%s\n' \
    archiso mkinitcpio-archiso syslinux grub efibootmgr dosfstools \
    squashfs-tools networkmanager lightdm lightdm-gtk-greeter \
    mate-session-manager mate-panel mate-control-center caja marco \
    mate-settings-daemon mate-terminal mate-themes mate-applets \
    mate-notification-daemon mate-power-manager mate-screensaver \
    mate-system-monitor mate-utils atril eom engrampa pluma \
    materia-gtk-theme papirus-icon-theme dconf noto-fonts
} | sed '/^[[:space:]]*#/d; /^[[:space:]]*$/d' | sort -u > "$PROFILE/packages.x86_64"

log "Aplicando configurações MATE, LightDM e identidade VENOM"
install -Dm644 "$ROOT/build/airootfs/etc/dconf/db/local.d/00-venom" \
  "$PROFILE/airootfs/etc/dconf/db/local.d/00-venom"
install -Dm644 "$ROOT/build/airootfs/etc/dconf/profile/user" \
  "$PROFILE/airootfs/etc/dconf/profile/user"
install -Dm644 "$ROOT/build/airootfs/etc/lightdm/lightdm-gtk-greeter.conf" \
  "$PROFILE/airootfs/etc/lightdm/lightdm-gtk-greeter.conf"
install -Dm644 "$ROOT/build/airootfs/etc/lightdm/lightdm.conf.d/10-venom-live.conf" \
  "$PROFILE/airootfs/etc/lightdm/lightdm.conf.d/10-venom-live.conf"
install -Dm644 "$ROOT/build/airootfs/etc/skel/.config/gtk-3.0/settings.ini" \
  "$PROFILE/airootfs/etc/skel/.config/gtk-3.0/settings.ini"
install -Dm644 "$ROOT/build/airootfs/etc/skel/.config/gtk-4.0/settings.ini" \
  "$PROFILE/airootfs/etc/skel/.config/gtk-4.0/settings.ini"
install -Dm644 "$PROFILE/pacman.conf" "$PROFILE/airootfs/etc/pacman.conf"
install -Dm644 "$ROOT/build/archiso/airootfs/etc/os-release" \
  "$PROFILE/airootfs/etc/os-release"
install -Dm644 "$ROOT/build/archiso/airootfs/etc/hostname" \
  "$PROFILE/airootfs/etc/hostname"
install -Dm644 "$ROOT/build/archiso/airootfs/etc/systemd/system/venom-live-user.service" \
  "$PROFILE/airootfs/etc/systemd/system/venom-live-user.service"
install -Dm755 "$ROOT/build/archiso/airootfs/usr/local/bin/venom-live-user-setup" \
  "$PROFILE/airootfs/usr/local/bin/venom-live-user-setup"
mkdir -p "$PROFILE/airootfs/etc/systemd/system/multi-user.target.wants" \
         "$PROFILE/airootfs/etc/systemd/system/graphical.target.wants"
ln -sfn ../venom-live-user.service \
  "$PROFILE/airootfs/etc/systemd/system/multi-user.target.wants/venom-live-user.service"
ln -sfn /usr/lib/systemd/system/lightdm.service \
  "$PROFILE/airootfs/etc/systemd/system/graphical.target.wants/lightdm.service"

log "Gerando fundo monocromático da VENOM OS"
install -d "$PROFILE/airootfs/usr/share/backgrounds/venom"
magick -size 1920x1080 xc:'#000000' \
  "$PROFILE/airootfs/usr/share/backgrounds/venom/venom-wallpaper.png"

log "Conferindo se o perfil não contém repositórios externos ao Arch"
if grep -Eiq 'endeavouros|eos-' "$PROFILE/pacman.conf" "$PROFILE/packages.x86_64"; then
  die "Foi encontrada referência ou pacote da distribuição anterior no perfil."
fi
grep -Eq '^\[core\]$' "$PROFILE/pacman.conf" || die "Repositório core do Arch ausente."
grep -Eq '^\[extra\]$' "$PROFILE/pacman.conf" || die "Repositório extra do Arch ausente."

log "Compilando a ISO VENOM OS com mkarchiso"
sudo mkarchiso -v -w "$WORK/mkarchiso-work" -o "$OUTPUT" "$PROFILE"

log "ISO(s) gerada(s)"
find "$OUTPUT" -maxdepth 1 -type f -name '*.iso' -printf '%f  %s bytes\n'

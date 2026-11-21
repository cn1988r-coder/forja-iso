#!/usr/bin/env bash
# shellcheck disable=SC2154
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
PROFILE="$ROOT/build"
PACKAGES="$PROFILE/packages.x86_64"
fail() { printf 'FALHA: %s\n' "$*" >&2; exit 1; }
for path in profiledef.sh pacman.conf packages.x86_64 airootfs/etc/pacman.conf syslinux/archiso_head.cfg syslinux/archiso_sys.cfg syslinux/archiso_sys-linux.cfg grub/grub.cfg airootfs/etc/mkinitcpio.conf.d/archiso.conf airootfs/root/.automated_script.sh airootfs/root/venom-live-setup; do
  [[ -f "$PROFILE/$path" ]] || fail "Arquivo obrigatório ausente: build/$path"
done
bash -n "$PROFILE/profiledef.sh" "$PROFILE/airootfs/root/.automated_script.sh" "$PROFILE/airootfs/root/venom-live-setup" "$ROOT/installer/backend/venom-install-backend"
(
  cd "$PROFILE"
  # shellcheck disable=SC1091
  source ./profiledef.sh
  [[ "$iso_name" == venom && "$arch" == x86_64 ]] || fail "Identidade ou arquitetura inválida."
  [[ " ${bootmodes[*]} " == *" bios.syslinux "* ]] || fail "Boot BIOS Syslinux ausente."
  [[ " ${bootmodes[*]} " == *" uefi.grub "* ]] || fail "Boot UEFI GRUB ausente."
  [[ "$packages" == packages.x86_64 ]] || fail "Manifest de pacotes incorreto."
  [[ " ${airootfs_image_tool_options[*]} " == *" zstd "* ]] || fail "Compressão SquashFS deve usar zstd."
)
grep -q '^pt_BR.UTF-8 UTF-8$' "$PROFILE/airootfs/etc/locale.gen" || fail "Locale pt_BR ausente."
grep -q '^LANG=pt_BR.UTF-8$' "$PROFILE/airootfs/etc/locale.conf" || fail "locale.conf incorreto."
grep -q '^KEYMAP=br-abnt2$' "$PROFILE/airootfs/etc/vconsole.conf" || fail "Teclado ABNT2 ausente."
grep -q '^HOOKS=.*archiso' "$PROFILE/airootfs/etc/mkinitcpio.conf.d/archiso.conf" || fail "Hooks Archiso ausentes."
grep -q '^COMPRESSION="zstd"$' "$PROFILE/airootfs/etc/mkinitcpio.conf.d/archiso.conf" || fail "Compressão initramfs deve usar zstd."
grep -q '^Server = https://geo.mirror.pkgbuild.com/' "$PROFILE/pacman.conf" || fail "Mirror oficial Arch ausente no perfil."
grep -q '^Server = https://geo.mirror.pkgbuild.com/' "$PROFILE/airootfs/etc/pacman.conf" || fail "Mirror oficial Arch ausente no ambiente live."
for package in base linux linux-firmware gtk4 archlinux-keyring arch-install-scripts mkinitcpio mkinitcpio-archiso mkinitcpio-nfs-utils nbd grub efibootmgr dosfstools e2fsprogs gptfdisk parted sudo curl networkmanager bluez lightdm lightdm-gtk-greeter mate-session-manager mate-panel caja marco; do
  grep -Fxq "$package" "$PACKAGES" || fail "Pacote obrigatório ausente do manifest: $package"
done
# Calamares é o instalador escolhido da VENOM OS; somente distribuições-base proibidas são bloqueadas aqui.
if grep -Eiq 'manjaro|endeavouros|biglinux' "$PACKAGES" "$PROFILE/pacman.conf"; then
  fail "Foi encontrada referência de distribuição proibida no perfil."
fi
duplicates="$(grep -Ev '^[[:space:]]*(#|$)' "$PACKAGES" | sort | uniq -d)"
[[ -z "$duplicates" ]] || fail "Pacotes duplicados: $duplicates"
if command -v pacman >/dev/null 2>&1; then
  while IFS= read -r package; do
    [[ -z "$package" || "$package" == \#* ]] && continue
    if ! pacman -Si "$package" >/dev/null 2>&1 && ! pacman -Sgq "$package" | grep -q .; then
      fail "Pacote/grupo não encontrado nos repositórios configurados: $package"
    fi
  done < "$PACKAGES"
fi
printf 'OK: perfil Archiso, BIOS/UEFI, locale, teclado, PXE e compressão passaram na validação estática.\n'

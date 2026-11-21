#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
PROFILE="$ROOT/build"
PACKAGES="$PROFILE/packages.x86_64"
INSTALL_PACKAGES="$PROFILE/install-packages.x86_64"
fail(){ printf 'FALHA: %s\n' "$*" >&2; exit 1; }

for path in profiledef.sh pacman.conf packages.x86_64 install-packages.x86_64 airootfs/etc/pacman.conf airootfs/etc/mkinitcpio.conf.d/archiso.conf airootfs/etc/locale.conf airootfs/etc/locale.gen airootfs/etc/vconsole.conf airootfs/root/.automated_script.sh airootfs/root/venom-live-setup syslinux/archiso_head.cfg syslinux/archiso_sys.cfg syslinux/archiso_sys-linux.cfg grub/grub.cfg; do
  [[ -s "$PROFILE/$path" ]] || fail "Arquivo obrigatório ausente: build/$path"
done
for script in "$PROFILE/profiledef.sh" "$PROFILE/airootfs/root/.automated_script.sh" "$PROFILE/airootfs/root/venom-live-setup"; do
  bash -n "$script" || fail "Sintaxe Bash inválida: $script"
done
python -m py_compile "$ROOT/installer/modules/venominstall/main.py" || fail "Sintaxe Python do módulo venominstall inválida."
(
  cd "$PROFILE"
  # shellcheck disable=SC1091
  source ./profiledef.sh
  [[ "$iso_name" == venom && "$arch" == x86_64 ]] || fail "Identidade/arquitetura inválida."
  [[ " ${bootmodes[*]} " == *" bios.syslinux "* && " ${bootmodes[*]} " == *" uefi.grub "* ]] || fail "Boot BIOS/UEFI incompleto."
  [[ "$packages" == packages.x86_64 ]] || fail "Manifest live incorreto."
  [[ " ${airootfs_image_tool_options[*]} " == *" zstd "* ]] || fail "SquashFS deve usar zstd."
)
grep -Fxq 'pt_BR.UTF-8 UTF-8' "$PROFILE/airootfs/etc/locale.gen" || fail "Locale pt_BR ausente."
grep -Fxq 'LANG=pt_BR.UTF-8' "$PROFILE/airootfs/etc/locale.conf" || fail "locale.conf incorreto."
grep -Fxq 'KEYMAP=br-abnt2' "$PROFILE/airootfs/etc/vconsole.conf" || fail "Teclado ABNT2 ausente."
grep -q '^HOOKS=.*archiso' "$PROFILE/airootfs/etc/mkinitcpio.conf.d/archiso.conf" || fail "Hooks Archiso ausentes."
grep -Fxq 'COMPRESSION="zstd"' "$PROFILE/airootfs/etc/mkinitcpio.conf.d/archiso.conf" || fail "Compressão initramfs deve usar zstd."
grep -q '^Server = https://geo.mirror.pkgbuild.com/' "$PROFILE/pacman.conf" || fail "Mirror oficial Arch ausente no perfil."
grep -q '^Server = https://geo.mirror.pkgbuild.com/' "$PROFILE/airootfs/etc/pacman.conf" || fail "Mirror oficial Arch ausente no live."
for package in base linux linux-firmware gtk4 archlinux-keyring arch-install-scripts mkinitcpio mkinitcpio-archiso mkinitcpio-nfs-utils nbd grub efibootmgr dosfstools e2fsprogs gptfdisk parted sudo curl networkmanager bluez lightdm lightdm-gtk-greeter mate-session-manager mate-panel caja marco; do
  grep -Fxq "$package" "$PACKAGES" || fail "Pacote obrigatório ausente do manifest live: $package"
done
for package in base linux linux-firmware archlinux-keyring pacman-mirrorlist grub efibootmgr mkinitcpio xorg-server lightdm lightdm-gtk-greeter networkmanager bluez pipewire mate-session-manager mate-panel caja marco; do
  grep -Fxq "$package" "$INSTALL_PACKAGES" || fail "Pacote obrigatório ausente do manifest de instalação: $package"
done
if grep -Eiq 'manjaro|endeavouros|biglinux' "$PACKAGES" "$INSTALL_PACKAGES" "$PROFILE/pacman.conf"; then
  fail "Foi encontrada referência de distribuição proibida na configuração operacional."
fi
if grep -Eiq '^(archiso|mkinitcpio-archiso|mkinitcpio-nfs-utils|nbd|squashfs-tools|syslinux|base-devel|linux-headers|linux-lts|linux-lts-headers)$' "$INSTALL_PACKAGES"; then
  fail "Manifesto de instalação contém ferramentas exclusivas da ISO/live."
fi
grep -Fq 'install -Dm644 build/install-packages.x86_64 build/airootfs/usr/share/venom/install-packages.x86_64' "$ROOT/.github/workflows/build-arch-iso.yml" || fail "Workflow não prepara o manifesto de instalação."
grep -Fxq 'installPackagesFile: /usr/share/venom/install-packages.x86_64' "$ROOT/installer/modules/venominstall/venominstall.conf" || fail "Calamares não aponta para o manifesto de instalação."
grep -q 'installPackagesFile' "$ROOT/installer/modules/venominstall/main.py" || fail "Módulo VENOM não usa installPackagesFile."
grep -q 'pacstrap' "$ROOT/installer/modules/venominstall/main.py" || fail "Instalador online pacstrap ausente."
duplicates="$(grep -Ev '^[[:space:]]*(#|$)' "$PACKAGES" | sort | uniq -d)"
[[ -z "$duplicates" ]] || fail "Pacotes duplicados no manifest live: $duplicates"
install_duplicates="$(grep -Ev '^[[:space:]]*(#|$)' "$INSTALL_PACKAGES" | sort | uniq -d)"
[[ -z "$install_duplicates" ]] || fail "Pacotes duplicados no manifest de instalação: $install_duplicates"
if command -v pacman >/dev/null 2>&1; then
  for manifest in "$PACKAGES" "$INSTALL_PACKAGES"; do
    while IFS= read -r package; do
      [[ -z "$package" || "$package" == \#* ]] && continue
      if ! pacman -Si "$package" >/dev/null 2>&1 && ! pacman -Sgq "$package" | grep -q .; then
        fail "Pacote/grupo não encontrado nos repositórios oficiais Arch: $package"
      fi
    done < "$manifest"
  done
fi
printf 'OK: perfil Archiso MATE, manifesto de instalação mínimo, BIOS/UEFI, locale, teclado, PXE e Calamares online passaram na validação estática.\n'

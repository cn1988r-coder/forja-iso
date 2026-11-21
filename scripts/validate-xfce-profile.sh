#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
P="$ROOT/build"
PKG="$P/packages.x86_64"
INSTALL_PKG="$P/install-packages.x86_64"
OVERLAY="$P/install-overlay"
fail(){ printf 'FALHA: %s\n' "$*" >&2; exit 1; }
for f in profiledef.sh pacman.conf packages.x86_64 install-packages.x86_64 airootfs/etc/pacman.conf airootfs/etc/mkinitcpio.conf.d/archiso.conf airootfs/etc/locale.conf airootfs/etc/locale.gen airootfs/etc/vconsole.conf airootfs/root/.automated_script.sh airootfs/root/venom-live-setup syslinux/archiso_head.cfg syslinux/archiso_sys.cfg syslinux/archiso_sys-linux.cfg grub/grub.cfg; do
  [[ -s "$P/$f" ]] || fail "Arquivo obrigatório ausente: build/$f"
done
[[ -d "$OVERLAY" ]] || fail "Overlay do sistema instalado ausente."
for script in "$P/profiledef.sh" "$P/airootfs/root/.automated_script.sh" "$P/airootfs/root/venom-live-setup"; do
  bash -n "$script" || fail "Sintaxe Bash inválida: $script"
done
python -m py_compile "$ROOT/installer/modules/venominstall/main.py" || fail "Sintaxe Python do módulo venominstall inválida."
(
  cd "$P"
  # shellcheck disable=SC1091
  source ./profiledef.sh
  [[ "$iso_name" == venom && "$arch" == x86_64 ]] || fail "Identidade/arquitetura inválida."
  [[ " ${bootmodes[*]} " == *" bios.syslinux "* && " ${bootmodes[*]} " == *" uefi.grub "* ]] || fail "Boot BIOS/UEFI incompleto."
  [[ "$packages" == packages.x86_64 ]] || fail "Manifest live incorreto."
  [[ " ${airootfs_image_tool_options[*]} " == *" zstd "* ]] || fail "SquashFS deve usar zstd."
)
grep -Fxq 'LANG=pt_BR.UTF-8' "$P/airootfs/etc/locale.conf" || fail "Locale incorreto."
grep -Fxq 'pt_BR.UTF-8 UTF-8' "$P/airootfs/etc/locale.gen" || fail "Locale pt_BR ausente."
grep -Fxq 'KEYMAP=br-abnt2' "$P/airootfs/etc/vconsole.conf" || fail "Teclado ABNT2 ausente."
grep -q '^HOOKS=.*archiso' "$P/airootfs/etc/mkinitcpio.conf.d/archiso.conf" || fail "Hooks Archiso ausentes."
grep -Fxq 'COMPRESSION="zstd"' "$P/airootfs/etc/mkinitcpio.conf.d/archiso.conf" || fail "Compressão do initramfs inválida."
grep -q '^Server = https://geo.mirror.pkgbuild.com/' "$P/pacman.conf" || fail "Mirror oficial Arch ausente."
grep -q '^Server = https://geo.mirror.pkgbuild.com/' "$P/airootfs/etc/pacman.conf" || fail "Mirror oficial Arch ausente no live."
grep -Fq 'install -Dm644 build/install-packages.x86_64 build/airootfs/usr/share/venom/install-packages.x86_64' "$ROOT/.github/workflows/build-arch-iso.yml" || fail "Workflow não prepara o manifesto de instalação."
grep -Fq 'cp -a build/install-overlay/. build/airootfs/usr/share/venom/install-overlay/' "$ROOT/.github/workflows/build-arch-iso.yml" || fail "Workflow não prepara o overlay de instalação."
grep -Fxq 'installPackagesFile: /usr/share/venom/install-packages.x86_64' "$ROOT/installer/modules/venominstall/venominstall.conf" || fail "Manifesto de instalação não configurado."
grep -Fxq 'installOverlay: /usr/share/venom/install-overlay' "$ROOT/installer/modules/venominstall/venominstall.conf" || fail "Overlay de instalação não configurado."
grep -q 'copy_install_overlay' "$ROOT/installer/modules/venominstall/main.py" || fail "Módulo VENOM não aplica o overlay."
grep -q 'pacstrap' "$ROOT/installer/modules/venominstall/main.py" || fail "Instalador online pacstrap ausente."
grep -q '      - locale' "$ROOT/installer/settings.conf" || fail "Módulo locale ausente da execução Calamares."
grep -q '      - keyboard' "$ROOT/installer/settings.conf" || fail "Módulo keyboard ausente da execução Calamares."
grep -q '      - users' "$ROOT/installer/settings.conf" || fail "Módulo users ausente da execução Calamares."
if grep -R -Eiq 'unpackfs|rsync|manjaro|endeavouros|biglinux|mhwd' "$ROOT/installer/settings.conf" "$ROOT/installer/modules/venominstall" "$PKG" "$INSTALL_PKG" "$P/pacman.conf"; then
  fail "Referência proibida ou instalação por cópia detectada."
fi
grep -Fxq 'user-session=xfce' "$P/airootfs/etc/lightdm/lightdm.conf.d/50-venom-live.conf" || fail "LightDM live não inicia XFCE."
for package in base linux linux-firmware archlinux-keyring arch-install-scripts mkinitcpio-archiso mkinitcpio-nfs-utils nbd xfce4 xfce4-goodies thunar lightdm lightdm-gtk-greeter networkmanager bluez blueman gtk4 qt6-base; do
  grep -Fxq "$package" "$PKG" || fail "Pacote obrigatório ausente do manifest live: $package"
done
for package in base linux linux-firmware archlinux-keyring pacman-mirrorlist grub efibootmgr mkinitcpio xorg-server lightdm lightdm-gtk-greeter networkmanager bluez pipewire xfce4 thunar; do
  grep -Fxq "$package" "$INSTALL_PKG" || fail "Pacote obrigatório ausente do manifest de instalação: $package"
done
if grep -Eiq '^(mate-session-manager|mate-panel|mate-control-center|caja|marco|mate-settings-daemon|windowmaker|manjaro|endeavouros|biglinux|mhwd|pamac-gtk)$' "$PKG" "$INSTALL_PKG"; then fail "Desktop adicional ou resíduo de outra distribuição no manifest."; fi
if grep -Eiq '^(archiso|mkinitcpio-archiso|mkinitcpio-nfs-utils|nbd|squashfs-tools|syslinux|base-devel|linux-headers|linux-lts|linux-lts-headers)$' "$INSTALL_PKG"; then fail "Manifesto de instalação contém ferramentas exclusivas da ISO/live."; fi
for f in etc/lightdm/lightdm-gtk-greeter.conf etc/lightdm/lightdm.conf.d/50-venom-session.conf etc/skel/.config/gtk-3.0/settings.ini etc/skel/.config/gtk-4.0/settings.ini etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml usr/share/backgrounds/venom/venom-black.svg; do
  [[ -s "$OVERLAY/$f" ]] || fail "Arquivo XFCE ausente no overlay: $f"
done
grep -q 'user-session=xfce' "$OVERLAY/etc/lightdm/lightdm.conf.d/50-venom-session.conf" || fail "Sessão XFCE instalada não configurada."
if grep -R -Eiq 'pamac|manjaro|docklike|unpackfs|rsync' "$OVERLAY" "$P/airootfs/etc/skel/.config/xfce4" "$ROOT/installer/modules/venominstall"; then fail "Overlay XFCE contém referência proibida ou plugin ausente."; fi
for manifest in "$PKG" "$INSTALL_PKG"; do
  duplicates="$(grep -Ev '^[[:space:]]*(#|$)' "$manifest" | sort | uniq -d)"
  [[ -z "$duplicates" ]] || fail "Pacotes duplicados em $manifest: $duplicates"
done
if command -v pacman >/dev/null 2>&1; then
  for manifest in "$PKG" "$INSTALL_PKG"; do
    while IFS= read -r package; do
      [[ -z "$package" || "$package" == \#* ]] && continue
      if ! pacman -Si "$package" >/dev/null 2>&1 && ! pacman -Sgq "$package" | grep -q .; then
        fail "Pacote/grupo não encontrado nos repositórios oficiais Arch: $package"
      fi
    done < "$manifest"
  done
fi
printf 'OK: perfil Archiso, manifestos separados, overlay, Calamares online e desktop passaram na validação estática.\n'

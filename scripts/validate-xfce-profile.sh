#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
P="$ROOT/build"
PKG="$P/packages.x86_64"
INSTALL_PKG="$P/install-packages.x86_64"
fail(){ printf 'FALHA: %s\n' "$*" >&2; exit 1; }
for f in profiledef.sh pacman.conf packages.x86_64 install-packages.x86_64 install-packages.x86_64 airootfs/etc/pacman.conf airootfs/etc/mkinitcpio.conf.d/archiso.conf airootfs/etc/locale.conf airootfs/etc/locale.gen airootfs/etc/vconsole.conf airootfs/root/.automated_script.sh airootfs/root/venom-live-setup syslinux/archiso_head.cfg syslinux/archiso_sys.cfg syslinux/archiso_sys-linux.cfg grub/grub.cfg; do
  [[ -s "$P/$f" ]] || fail "Arquivo obrigatório ausente: build/$f"
done
for script in "$P/profiledef.sh" "$P/airootfs/root/.automated_script.sh" "$P/airootfs/root/venom-live-setup"; do bash -n "$script" || fail "Sintaxe Bash inválida: $script"; done
python -m py_compile "$ROOT/installer/modules/venominstall/main.py" || fail "Sintaxe Python do módulo venominstall inválida."
(
  cd "$P"
  # shellcheck disable=SC1091
  source ./profiledef.sh
  [[ "$iso_name" == venom && "$arch" == x86_64 ]] || fail "Identidade/arquitetura inválida."
  [[ " ${bootmodes[*]} " == *" bios.syslinux "* && " ${bootmodes[*]} " == *" uefi.grub "* ]] || fail "Boot BIOS/UEFI incompleto."
  [[ "$packages" == packages.x86_64 ]] || fail "Manifest incorreto."
  [[ " ${airootfs_image_tool_options[*]} " == *" zstd "* ]] || fail "SquashFS deve usar zstd."
)
grep -Fxq 'LANG=pt_BR.UTF-8' "$P/airootfs/etc/locale.conf" || fail "Locale incorreto."
grep -Fxq 'pt_BR.UTF-8 UTF-8' "$P/airootfs/etc/locale.gen" || fail "Locale pt_BR não habilitado."
grep -Fxq 'KEYMAP=br-abnt2' "$P/airootfs/etc/vconsole.conf" || fail "Teclado ABNT2 ausente."
grep -q '^HOOKS=.*archiso' "$P/airootfs/etc/mkinitcpio.conf.d/archiso.conf" || fail "Hooks Archiso ausentes."
grep -Fxq 'COMPRESSION="zstd"' "$P/airootfs/etc/mkinitcpio.conf.d/archiso.conf" || fail "Compressão do initramfs inválida."
for p in base linux linux-firmware archlinux-keyring arch-install-scripts mkinitcpio-archiso mkinitcpio-nfs-utils nbd xfce4 xfce4-goodies thunar lightdm lightdm-gtk-greeter networkmanager bluez blueman gtk4 qt6-base; do
  grep -Fxq "$p" "$PKG" || fail "Pacote/grupo obrigatório ausente: $p"
done
if grep -Eiq '^(mate-session-manager|mate-panel|mate-control-center|caja|marco|mate-settings-daemon|manjaro|endeavouros|biglinux|mhwd|pamac-gtk)$' "$PKG"; then
  fail "Pacote de desktop incorreto ou resíduo de outra distribuição no manifest."
fi
grep -q '^Server = https://geo.mirror.pkgbuild.com/' "$P/pacman.conf" || fail "Mirror oficial Arch ausente."
grep -q '^Server = https://geo.mirror.pkgbuild.com/' "$P/airootfs/etc/pacman.conf" || fail "Mirror oficial Arch ausente na sessão live."
grep -Fxq "user-session=xfce" "$P/airootfs/etc/lightdm/lightdm.conf.d/50-venom-live.conf" || fail "LightDM não inicia XFCE."
for f in "$ROOT/installer/settings.conf" "$ROOT/installer/branding/branding.desc" "$ROOT"/installer/modules/*/*.conf; do
  [[ -f "$f" ]] || continue
  python - "$f" <<'PY'
import pathlib, sys, yaml
yaml.safe_load(pathlib.Path(sys.argv[1]).read_text())
PY
done
python -m py_compile "$ROOT/installer/modules/venominstall/main.py"
grep -q 'pacstrap' "$ROOT/installer/modules/venominstall/main.py" || fail "Instalador online pacstrap ausente."
[[ -s "$INSTALL_PKG" ]] || fail "Manifesto de instalação ausente."
for package in base linux archlinux-keyring grub efibootmgr lightdm networkmanager bluez pipewire xfce4 thunar; do
  grep -Fxq "$package" "$INSTALL_PKG" || fail "Pacote obrigatório ausente do manifesto de instalação: $package"
done
if grep -Eiq '^(archiso|mkinitcpio-archiso|mkinitcpio-nfs-utils|nbd|squashfs-tools|syslinux|base-devel|linux-headers|linux-lts|linux-lts-headers)
if grep -R -Eiq 'unpackfs|rsync|manjaro|endeavouros|biglinux|mhwd' "$ROOT/installer/settings.conf" "$ROOT/installer/modules/venominstall" "$PKG" "$P/pacman.conf"; then
  fail "Referência proibida ou instalação por cópia detectada."
fi
for f in "$P/airootfs/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml" "$P/airootfs/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml" "$P/airootfs/etc/skel/.config/gtk-3.0/settings.ini"; do
  [[ -s "$f" ]] || fail "Configuração XFCE ausente: $f"
done
if command -v pacman >/dev/null 2>&1; then
  while IFS= read -r package; do
    [[ -z "$package" || "$package" == \#* ]] && continue
    if ! pacman -Si "$package" >/dev/null 2>&1 && ! pacman -Sgq "$package" | grep -q .; then
      fail "Pacote/grupo ausente dos repositórios oficiais Arch: $package"
    fi
  done < "$PKG"
  while IFS= read -r package; do
    [[ -z "$package" || "$package" == \\#* ]] && continue
    if ! pacman -Si "$package" >/dev/null 2>&1 && ! pacman -Sgq "$package" | grep -q .; then
      fail "Pacote/grupo do sistema instalado ausente dos repositórios oficiais Arch: $package"
    fi
  done < "$INSTALL_PKG"
fi
install_duplicates="$(grep -Ev '^[[:space:]]*(#|$)' "$INSTALL_PKG" | sort | uniq -d)"
[[ -z "$install_duplicates" ]] || fail "Pacotes duplicados no manifesto de instalação: $install_duplicates"
duplicates="$(grep -Ev '^[[:space:]]*(#|$)' "$PKG" | sort | uniq -d)"
[[ -z "$duplicates" ]] || fail "Pacotes duplicados: $duplicates"
printf 'OK: perfil Archiso XFCE, BIOS/UEFI, locale, teclado, PXE, Calamares online e manifest passaram na validação estática.\n'
 "$INSTALL_PKG"; then
  fail "Manifesto de instalação contém ferramentas exclusivas da ISO/live."
fi
grep -Fq 'install -Dm644 build/install-packages.x86_64 build/airootfs/usr/share/venom/install-packages.x86_64' "$ROOT/.github/workflows/build-arch-iso.yml" || fail "Workflow não está preparando o manifesto de instalação."
grep -Fq 'installPackagesFile: /usr/share/venom/install-packages.x86_64' "$ROOT/installer/modules/venominstall/venominstall.conf" || fail "Calamares não aponta para o manifesto de instalação."
grep -q 'installPackagesFile' "$ROOT/installer/modules/venominstall/main.py" || fail "Módulo VENOM não usa installPackagesFile."
  grep -Fxq "xfce4" "$INSTALL_PKG" || fail "Pacote obrigatório ausente do manifesto de instalação: xfce4"
  grep -Fxq "thunar" "$INSTALL_PKG" || fail "Pacote obrigatório ausente do manifesto de instalação: thunar"

if grep -R -Eiq 'unpackfs|rsync|manjaro|endeavouros|biglinux|mhwd' "$ROOT/installer/settings.conf" "$ROOT/installer/modules/venominstall" "$PKG" "$P/pacman.conf"; then
  fail "Referência proibida ou instalação por cópia detectada."
fi
for f in "$P/airootfs/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml" "$P/airootfs/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml" "$P/airootfs/etc/skel/.config/gtk-3.0/settings.ini"; do
  [[ -s "$f" ]] || fail "Configuração XFCE ausente: $f"
done
if command -v pacman >/dev/null 2>&1; then
  while IFS= read -r package; do
    [[ -z "$package" || "$package" == \#* ]] && continue
    if ! pacman -Si "$package" >/dev/null 2>&1 && ! pacman -Sgq "$package" | grep -q .; then
      fail "Pacote/grupo ausente dos repositórios oficiais Arch: $package"
    fi
  done < "$PKG"
fi
duplicates="$(grep -Ev '^[[:space:]]*(#|$)' "$PKG" | sort | uniq -d)"
[[ -z "$duplicates" ]] || fail "Pacotes duplicados: $duplicates"
printf 'OK: perfil Archiso XFCE, BIOS/UEFI, locale, teclado, PXE, Calamares online e manifest passaram na validação estática.\n'

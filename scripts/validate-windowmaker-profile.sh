#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
P="$ROOT/build"
PKG="$P/packages.x86_64"
fail(){ printf 'FALHA: %s\n' "$*" >&2; exit 1; }
for f in profiledef.sh pacman.conf packages.x86_64 airootfs/etc/pacman.conf airootfs/etc/mkinitcpio.conf.d/archiso.conf airootfs/etc/locale.conf airootfs/etc/locale.gen airootfs/etc/vconsole.conf airootfs/root/.automated_script.sh airootfs/root/venom-live-setup syslinux/archiso_head.cfg syslinux/archiso_sys.cfg syslinux/archiso_sys-linux.cfg grub/grub.cfg; do
  [[ -s "$P/$f" ]] || fail "Arquivo obrigatório ausente: build/$f"
done
bash -n "$P/profiledef.sh" "$P/airootfs/root/.automated_script.sh" "$P/airootfs/root/venom-live-setup" "$P/airootfs/usr/local/bin/venom-windowmaker-session" || fail "Sintaxe Bash inválida."
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
for p in base linux linux-firmware archlinux-keyring arch-install-scripts mkinitcpio-archiso mkinitcpio-nfs-utils nbd windowmaker xorg-server lightdm lightdm-gtk-greeter networkmanager bluez blueman gtk4 qt6-base tint2 xterm; do
  grep -Fxq "$p" "$PKG" || fail "Pacote obrigatório ausente: $p"
done
if grep -Eiq '^(mate-session-manager|mate-panel|mate-control-center|caja|marco|xfce4|xfce4-panel|xfce4-session|xfdesktop|xfwm4|lxqt|lxqt-session|manjaro|endeavouros|biglinux|mhwd|pamac-gtk)$' "$PKG"; then
  fail "Desktop adicional ou resíduo de outra distribuição no manifest."
fi
grep -q '^Server = https://geo.mirror.pkgbuild.com/' "$P/pacman.conf" || fail "Mirror oficial Arch ausente."
grep -q '^Server = https://geo.mirror.pkgbuild.com/' "$P/airootfs/etc/pacman.conf" || fail "Mirror oficial Arch ausente na sessão live."
for f in "$ROOT/installer/settings.conf" "$ROOT/installer/branding/branding.desc" "$ROOT"/installer/modules/*/*.conf; do
  [[ -f "$f" ]] || continue
  python - "$f" <<'PY'
import pathlib, sys, yaml
yaml.safe_load(pathlib.Path(sys.argv[1]).read_text())
PY
done
python -m py_compile "$ROOT/installer/modules/venominstall/main.py"
grep -q 'pacstrap' "$ROOT/installer/modules/venominstall/main.py" || fail "Instalador online pacstrap ausente."
if grep -R -Eiq 'unpackfs|rsync|manjaro|endeavouros|biglinux|mhwd' "$ROOT/installer/settings.conf" "$ROOT/installer/modules/venominstall" "$PKG" "$P/pacman.conf"; then
  fail "Referência proibida ou instalação por cópia detectada."
fi
[[ -s "$P/airootfs/usr/share/xsessions/venom-windowmaker.desktop" ]] || fail "Sessão Window Maker do LightDM ausente."
grep -Fxq 'user-session=windowmaker' "$P/airootfs/etc/lightdm/lightdm.conf.d/50-venom-live.conf" || fail "LightDM não inicia Window Maker."
[[ -x "$P/airootfs/usr/local/bin/venom-windowmaker-session" ]] || fail "Launcher da sessão Window Maker ausente ou não executável."
[[ -s "$P/airootfs/usr/share/backgrounds/venom/venom-windowmaker.svg" ]] || fail "Wallpaper VENOM Window Maker ausente."
duplicates="$(grep -Ev '^[[:space:]]*(#|$)' "$PKG" | sort | uniq -d)"
[[ -z "$duplicates" ]] || fail "Pacotes duplicados: $duplicates"
printf 'OK: perfil Archiso Window Maker, BIOS/UEFI, locale, teclado, PXE, Calamares online e sessão exclusiva passaram na validação estática.\n'

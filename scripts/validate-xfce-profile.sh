#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
P="$ROOT/build"
PKG="$P/packages.x86_64"
INSTALL_PKG="$P/install-packages.x86_64"
AUR_PKG="$P/aur-packages.x86_64"
OVERLAY="$P/install-overlay"
fail(){ printf 'FALHA: %s\n' "$*" >&2; exit 1; }
for f in profiledef.sh pacman.conf packages.x86_64 install-packages.x86_64 aur-packages.x86_64 airootfs/usr/share/venom/pacman-install.conf airootfs/etc/pacman.conf airootfs/etc/mkinitcpio.conf.d/archiso.conf airootfs/etc/locale.conf airootfs/etc/locale.gen airootfs/etc/vconsole.conf airootfs/root/.bash_profile airootfs/usr/local/lib/venom/venom-live-setup airootfs/usr/local/lib/venom/venom-live-ready airootfs/etc/systemd/system/venom-live-setup.service airootfs/etc/systemd/system/venom-live-ready.service syslinux/archiso_head.cfg syslinux/archiso_sys.cfg syslinux/archiso_sys-linux.cfg grub/grub.cfg; do
  [[ -s "$P/$f" ]] || fail "Arquivo obrigatório ausente: build/$f"
done
[[ -d "$OVERLAY" ]] || fail "Overlay XFCE ausente."
for script in "$P/profiledef.sh" "$P/airootfs/root/.bash_profile" "$P/airootfs/usr/local/lib/venom/venom-live-setup" "$P/airootfs/usr/local/lib/venom/venom-live-ready" "$ROOT/installer/venom-install"; do
  bash -n "$script" || fail "Sintaxe Bash inválida: $script"
done
(
 cd "$P"
 source ./profiledef.sh
 [[ "$iso_name" == venom && "$arch" == x86_64 ]] || fail "Identidade/arquitetura inválida."
 [[ " ${bootmodes[*]} " == *" bios.syslinux "* && " ${bootmodes[*]} " == *" uefi.grub "* ]] || fail "Boot BIOS/UEFI incompleto."
 [[ "$packages" == packages.x86_64 ]] || fail "Manifesto live incorreto."
 [[ "$kernel_params_x86_64" == *"systemd.firstboot=headless"* ]] || fail "First boot live interativo."
)
grep -Fxq 'LANG=pt_BR.UTF-8' "$P/airootfs/etc/locale.conf" || fail "Locale pt_BR ausente."
grep -Fxq 'pt_BR.UTF-8 UTF-8' "$P/airootfs/etc/locale.gen" || fail "Locale pt_BR não será gerado."
grep -Fxq 'KEYMAP=br-abnt2' "$P/airootfs/etc/vconsole.conf" || fail "Teclado ABNT2 ausente."
grep -Fq 'systemctl start venom-live-setup.service' "$P/airootfs/root/.bash_profile" || fail "Setup live não é disparado."
grep -Fq 'groupadd --system autologin' "$P/airootfs/usr/local/lib/venom/venom-live-setup" || fail "Grupo autologin ausente."
grep -Fq 'usermod --append --groups autologin venom' "$P/airootfs/usr/local/lib/venom/venom-live-setup" || fail "Usuário Live sem grupo autologin."
grep -Fq 'venom ALL=(root) NOPASSWD: /usr/lib/venom/venom-install' "$P/airootfs/usr/local/lib/venom/venom-live-setup" || fail "Permissão do instalador ausente."
grep -Fq '/home/venom/Desktop/Instalar-VENOM-OS.desktop' "$P/airootfs/usr/local/lib/venom/venom-live-setup" || fail "Atalho do instalador ausente da área de trabalho Live."
grep -Fq 'install -m 0644 /etc/pacman.conf /mnt/etc/pacman.conf' "$ROOT/installer/venom-install" || fail "Pacman.conf limpo não é instalado no sistema de destino."
grep -Fq 'SUDO_UID' "$ROOT/installer/venom-install" || fail "Arquivo temporário da senha não valida o usuário de origem."
grep -Fq 'After=lightdm.service' "$P/airootfs/etc/systemd/system/venom-live-ready.service" || fail "Verificador não aguarda LightDM."
grep -Fq 'VENOM_LIVE_READY' "$P/airootfs/usr/local/lib/venom/venom-live-ready" || fail "Marcador de prontidão ausente."
for process in xfce4-session xfce4-panel xfdesktop; do grep -Fq "pgrep -u venom -x $process" "$P/airootfs/usr/local/lib/venom/venom-live-ready" || fail "Prontidão não verifica $process."; done
grep -q '^Server = https://geo.mirror.pkgbuild.com/' "$P/pacman.conf" || fail "Mirror oficial ausente."
grep -Fq '/usr/share/venom/aur-repo' "$P/airootfs/usr/share/venom/pacman-install.conf" || fail "Repositório Pamac local ausente."
if grep -Fq '/usr/share/venom/aur-repo' "$P/airootfs/etc/pacman.conf"; then fail "Repositório AUR temporário não pode ficar no pacman.conf Live."; fi
for f in etc/lightdm/lightdm-gtk-greeter.conf etc/lightdm/lightdm.conf.d/50-venom-session.conf etc/skel/.config/gtk-3.0/settings.ini etc/skel/.config/gtk-4.0/settings.ini etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml etc/xdg/xfce4/panel/docklike.rc usr/share/backgrounds/venom/venom-black.svg; do [[ -s "$OVERLAY/$f" ]] || fail "Arquivo do overlay ausente: $f"; done
grep -Fq 'user-session=xfce' "$OVERLAY/etc/lightdm/lightdm.conf.d/50-venom-session.conf" || fail "Sessão XFCE instalada não configurada."
grep -Fq 'install -Dm644 build/install-packages.x86_64 build/airootfs/usr/share/venom/install-packages.x86_64' "$ROOT/.github/workflows/build-arch-iso.yml" || fail "Workflow não prepara o manifesto de pacotes."
grep -Fq 'cp -a build/install-overlay/. build/airootfs/usr/share/venom/install-overlay/' "$ROOT/.github/workflows/build-arch-iso.yml" || fail "Workflow não prepara o overlay."
grep -Fq 'meson setup' "$ROOT/.github/workflows/build-arch-iso.yml" || fail "Workflow não compila o instalador."
grep -Fq 'extra-cmake-modules gtk4 python' "$ROOT/.github/workflows/build-arch-iso.yml" || fail "Dependência GTK4 ausente do ambiente de compilação."
grep -Fq 'Exec=venom-installer' "$ROOT/installer/venom-installer.desktop" || fail "Atalho do instalador incorreto."
for package in base linux linux-lts linux-firmware archlinux-keyring arch-install-scripts gtk4 parted gptfdisk dosfstools e2fsprogs sudo curl grub xfce4 lightdm networkmanager; do
 grep -Fxq "$package" "$PKG" || fail "Pacote Live ausente: $package"
done
for package in base linux linux-lts linux-firmware archlinux-keyring pacman-mirrorlist grub efibootmgr mkinitcpio xorg-server lightdm networkmanager bluez pipewire xfce4 thunar sudo; do
 grep -Fxq "$package" "$INSTALL_PKG" || fail "Pacote instalado ausente: $package"
done
for manifest in "$PKG" "$INSTALL_PKG"; do
 duplicates="$(grep -Ev '^[[:space:]]*(#|$)' "$manifest" | sort | uniq -d)"
 [[ -z "$duplicates" ]] || fail "Pacotes duplicados em $manifest: $duplicates"
done
for package in libpamac-aur pamac-aur; do
 grep -Fxq "$package" "$AUR_PKG" || fail "Pacote AUR ausente do manifesto AUR."
 grep -Fxq "$package" "$PKG" || fail "Pacote AUR ausente do Live."
 grep -Fxq "$package" "$INSTALL_PKG" || fail "Pacote AUR ausente da instalação."
done
if grep -Eiq 'calamares|manjaro|endeavouros|biglinux|mhwd' "$ROOT/installer/venom-installer.desktop" "$ROOT/installer/venom-install" "$ROOT/.github/workflows/build-arch-iso.yml" "$P/airootfs/usr/local/lib/venom/venom-live-setup"; then fail "Integração antiga ou resíduo de outra distribuição encontrado."; fi
printf 'OK: perfil Archiso, XFCE, instalador VENOM, manifestos e boot BIOS/UEFI passaram na validação estática.\n'

#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
P="$ROOT/build"
PKG="$P/packages.x86_64"
INSTALL_PKG="$P/install-packages.x86_64"
AUR_PKG="$P/aur-packages.x86_64"
OVERLAY="$P/install-overlay"
fail(){ printf 'FALHA: %s
' "$*" >&2; exit 1; }
for f in profiledef.sh pacman.conf packages.x86_64 install-packages.x86_64 aur-packages.x86_64 airootfs/etc/pacman.conf airootfs/etc/mkinitcpio.conf.d/archiso.conf airootfs/etc/locale.conf airootfs/etc/locale.gen airootfs/etc/vconsole.conf airootfs/root/.bash_profile airootfs/usr/local/lib/venom/venom-live-setup airootfs/usr/local/lib/venom/venom-live-ready airootfs/etc/systemd/system/venom-live-setup.service airootfs/etc/systemd/system/venom-live-ready.service syslinux/archiso_head.cfg syslinux/archiso_sys.cfg syslinux/archiso_sys-linux.cfg grub/grub.cfg; do
  [[ -s "$P/$f" ]] || fail "Arquivo obrigatório ausente: build/$f"
done
[[ -d "$OVERLAY" ]] || fail "Overlay do sistema instalado ausente."
for script in "$P/profiledef.sh" "$P/airootfs/root/.bash_profile" "$P/airootfs/usr/local/lib/venom/venom-live-setup" "$P/airootfs/usr/local/lib/venom/venom-live-ready"; do
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
  [[ "$kernel_params_x86_64" == *"systemd.firstboot=headless"* ]] || fail "First boot do live não pode solicitar configuração interativa."
  [[ " ${airootfs_image_tool_options[*]} " == *" zstd "* ]] || fail "SquashFS deve usar zstd."
)
grep -Fxq 'LANG=pt_BR.UTF-8' "$P/airootfs/etc/locale.conf" || fail "Locale incorreto."
grep -Fxq 'pt_BR.UTF-8 UTF-8' "$P/airootfs/etc/locale.gen" || fail "Locale pt_BR ausente."
grep -Fxq 'KEYMAP=br-abnt2' "$P/airootfs/etc/vconsole.conf" || fail "Teclado ABNT2 ausente."
grep -Fq 'systemctl start venom-live-setup.service' "$P/airootfs/root/.bash_profile" || fail "tty1 não inicia setup via systemd."
grep -Fq '/dev/tty1' "$P/airootfs/root/.bash_profile" || fail "Setup live deve ser disparado somente no tty1."
grep -Fq 'ExecStart=/usr/bin/bash /usr/local/lib/venom/venom-live-setup' "$P/airootfs/etc/systemd/system/venom-live-setup.service" || fail "Unit systemd não chama setup live."
grep -Fq 'groupadd --system autologin' "$P/airootfs/usr/local/lib/venom/venom-live-setup" || fail "Grupo exigido pelo PAM do LightDM não é criado."
grep -Fq 'usermod --append --groups autologin venom' "$P/airootfs/usr/local/lib/venom/venom-live-setup" || fail "Usuário live não recebe o grupo autologin."
grep -Fq 'StandardOutput=journal+console' "$P/airootfs/etc/systemd/system/venom-live-setup.service" || fail "Unit live não encaminha logs ao console."
grep -Fq 'After=lightdm.service' "$P/airootfs/etc/systemd/system/venom-live-ready.service" || fail "Verificador de prontidão não aguarda LightDM."
[[ "$(head -n1 "$P/syslinux/archiso_sys.cfg")" == "SERIAL 0 115200" ]] || fail "SERIAL precisa ser a primeira diretiva do Syslinux BIOS para inicializar a porta COM1."
if grep -Fxq 'SERIAL 0 115200' "$P/syslinux/archiso_head.cfg"; then fail "SERIAL não pode ficar apenas em arquivo incluído; deve ser a primeira diretiva do arquivo de configuração BIOS."; fi
grep -Fq 'VENOM_LIVE_READY' "$P/airootfs/usr/local/lib/venom/venom-live-ready" || fail "Marcador de prontidão ausente do verificador."
for process in xfce4-session xfce4-panel xfdesktop; do
  grep -Fq "pgrep -u venom -x $process" "$P/airootfs/usr/local/lib/venom/venom-live-ready" || fail "Prontidão não verifica o processo XFCE $process."
done
grep -Fxq 'TimeoutStartSec=150' "$P/airootfs/etc/systemd/system/venom-live-ready.service" || fail "Timeout do verificador XFCE insuficiente."
grep -q '^HOOKS=.*archiso' "$P/airootfs/etc/mkinitcpio.conf.d/archiso.conf" || fail "Hooks Archiso ausentes."
grep -Fxq 'COMPRESSION="zstd"' "$P/airootfs/etc/mkinitcpio.conf.d/archiso.conf" || fail "Compressão do initramfs inválida."
grep -q '^Server = https://geo.mirror.pkgbuild.com/' "$P/pacman.conf" || fail "Mirror oficial Arch ausente."
grep -q '^Server = https://geo.mirror.pkgbuild.com/' "$P/airootfs/etc/pacman.conf" || fail "Mirror oficial Arch ausente no live."
grep -Fq '/usr/share/venom/aur-repo' "$P/airootfs/etc/pacman.conf" || fail "Repositório local AUR da ISO ausente."
grep -Fxq 'EnableAUR = true' "$P/airootfs/etc/pamac.conf" || fail "Pamac Live não habilita AUR."
grep -Fxq 'EnableAUR = true' "$OVERLAY/etc/pamac.conf" || fail "Pamac instalado não habilita AUR."
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
if grep -R -Eiq 'manjaro|docklike|unpackfs|rsync' "$OVERLAY" "$P/airootfs/etc/skel/.config/xfce4" "$ROOT/installer/modules/venominstall"; then fail "Overlay XFCE contém referência proibida ou plugin ausente."; fi
for manifest in "$PKG" "$INSTALL_PKG"; do
  duplicates="$(grep -Ev '^[[:space:]]*(#|$)' "$manifest" | sort | uniq -d)"
  [[ -z "$duplicates" ]] || fail "Pacotes duplicados em $manifest: $duplicates"
done
if command -v pacman >/dev/null 2>&1; then
  for manifest in "$PKG" "$INSTALL_PKG"; do
    while IFS= read -r package; do
      [[ -z "$package" || "$package" == \#* ]] && continue
      if ! grep -Fxq "$package" "$AUR_PKG" && ! pacman -Si "$package" >/dev/null 2>&1 && ! pacman -Sgq "$package" | grep -q .; then
        fail "Pacote/grupo não encontrado nos repositórios oficiais Arch: $package"
      fi
    done < "$manifest"
  done
fi
for package in libpamac-aur pamac-aur; do
  grep -Fxq "$package" "$AUR_PKG" || fail "Pacote AUR obrigatório ausente: $package"
  grep -Fxq "$package" "$PKG" || fail "Pacote AUR ausente do manifest live: $package"
  grep -Fxq "$package" "$INSTALL_PKG" || fail "Pacote AUR ausente do manifest de instalação: $package"
done
printf 'OK: perfil Archiso, manifestos separados, overlay, Calamares online e desktop passaram na validação estática.
'

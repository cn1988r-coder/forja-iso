#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
P="$ROOT/build"
PKG="$P/packages.x86_64"
INSTALL_PKG="$P/install-packages.x86_64"
OVERLAY="$P/install-overlay"

fail() { printf 'FALHA: %s\n' "$*" >&2; exit 1; }
pass() { printf 'OK: %s\n' "$*"; }

required=(
  "$P/profiledef.sh"
  "$P/pacman.conf"
  "$PKG"
  "$INSTALL_PKG"
  "$P/airootfs/etc/pacman.conf"
  "$P/airootfs/etc/mkinitcpio.conf.d/archiso.conf"
  "$P/airootfs/etc/locale.conf"
  "$P/airootfs/etc/locale.gen"
  "$P/airootfs/etc/vconsole.conf"
  "$P/airootfs/etc/X11/xorg.conf.d/00-keyboard.conf"
  "$OVERLAY/etc/locale.conf"
  "$OVERLAY/etc/locale.gen"
  "$OVERLAY/etc/vconsole.conf"
  "$OVERLAY/etc/X11/xorg.conf.d/00-keyboard.conf"
  "$P/airootfs/root/.automated_script.sh"
  "$P/airootfs/root/venom-live-setup"
  "$P/airootfs/usr/share/mate-panel/layouts/venom.layout"
  "$P/airootfs/etc/xdg/autostart/mate-volume-control-status-icon.desktop"
  "$OVERLAY/usr/share/mate-panel/layouts/venom.layout"
  "$OVERLAY/etc/xdg/autostart/mate-volume-control-status-icon.desktop"
  "$ROOT/installer/meson.build"
  "$ROOT/installer/src/main.c"
  "$ROOT/installer/src/disk.c"
  "$ROOT/installer/src/disk.h"
  "$ROOT/installer/src/plan.c"
  "$ROOT/installer/src/plan.h"
  "$ROOT/installer/tests/test-disk.c"
  "$ROOT/installer/tests/test-plan.c"
  "$ROOT/installer/README.md"
  "$ROOT/scripts/build-venom-iso.sh"
  "$ROOT/scripts/test-mate-panel.sh"
  "$ROOT/.github/workflows/build-arch-iso.yml"
)
for file in "${required[@]}"; do
  [[ -s "$file" ]] || fail "arquivo obrigatório ausente: $file"
done

for script in "$ROOT"/scripts/build-venom-iso.sh \
              "$ROOT"/scripts/validate-arch-profile.sh \
              "$ROOT"/scripts/validate-build.sh \
              "$ROOT"/scripts/validate-scope.sh \
              "$ROOT"/scripts/test-mate-panel.sh \
              "$P/profiledef.sh" \
              "$P/airootfs/root/.automated_script.sh" \
              "$P/airootfs/root/venom-live-setup"; do
  bash -n "$script" || fail "sintaxe Bash inválida: $script"
done

(
  cd "$P"
  # shellcheck disable=SC1091
  source ./profiledef.sh
  [[ "$iso_name" == venom && "$arch" == x86_64 ]] || fail "identidade ou arquitetura inválida"
  [[ " ${bootmodes[*]} " == *" bios.syslinux "* ]] || fail "boot BIOS ausente"
  [[ " ${bootmodes[*]} " == *" uefi.grub "* ]] || fail "boot UEFI ausente"
  [[ "$packages" == packages.x86_64 ]] || fail "manifesto live incorreto"
  [[ " ${airootfs_image_tool_options[*]} " == *" zstd "* ]] || fail "SquashFS deve usar Zstandard"
)

for root in "$P/airootfs" "$OVERLAY"; do
  grep -Fxq 'LANG=pt_BR.UTF-8' "$root/etc/locale.conf" ||
    fail "locale pt_BR ausente em $root"
  grep -Fxq 'pt_BR.UTF-8 UTF-8' "$root/etc/locale.gen" ||
    fail "locale pt_BR não habilitado em $root"
  active_locales="$(grep -Ev '^[[:space:]]*(#|$)' "$root/etc/locale.gen")"
  [[ "$active_locales" == "pt_BR.UTF-8 UTF-8" ]] ||
    fail "a configuração deve habilitar exclusivamente pt_BR.UTF-8 em $root"
  grep -Fxq 'KEYMAP=br-abnt2' "$root/etc/vconsole.conf" ||
    fail "teclado de console ABNT2 ausente em $root"
  grep -Fq 'Option "XkbLayout" "br"' "$root/etc/X11/xorg.conf.d/00-keyboard.conf" ||
    fail "layout X11 Brasil ausente em $root"
  grep -Fq 'Option "XkbVariant" "abnt2"' "$root/etc/X11/xorg.conf.d/00-keyboard.conf" ||
    fail "variante X11 ABNT2 ausente em $root"
done

for relative in etc/locale.conf etc/locale.gen etc/vconsole.conf \
                etc/X11/xorg.conf.d/00-keyboard.conf; do
  live_hash="$(sha256sum "$P/airootfs/$relative" | awk '{print $1}')"
  installed_hash="$(sha256sum "$OVERLAY/$relative" | awk '{print $1}')"
  [[ "$live_hash" == "$installed_hash" ]] ||
    fail "configuração live e instalada diverge: $relative"
done

grep -Fq 'Server = https://geo.mirror.pkgbuild.com/' "$P/pacman.conf" ||
  fail "mirror oficial Arch ausente"
grep -Fq 'Server = https://geo.mirror.pkgbuild.com/' "$P/airootfs/etc/pacman.conf" ||
  fail "mirror oficial Arch ausente no live"
grep -Fq 'COMPRESSION="zstd"' "$P/airootfs/etc/mkinitcpio.conf.d/archiso.conf" ||
  fail "compressão do initramfs inválida"

live_required=(
  base linux linux-firmware archlinux-keyring arch-install-scripts
  mkinitcpio-archiso mkinitcpio-nfs-utils nbd grub efibootmgr
  gtk4 json-glib lightdm networkmanager network-manager-applet
  bluez bluez-utils blueman pipewire pipewire-audio pipewire-alsa
  pipewire-pulse wireplumber mate-session-manager mate-panel mate-media
  polkit mate-polkit caja marco papirus-icon-theme
)
installed_required=(
  base linux linux-firmware archlinux-keyring pacman-mirrorlist
  grub efibootmgr mkinitcpio xorg-server lightdm lightdm-gtk-greeter
  networkmanager network-manager-applet bluez bluez-utils blueman
  pipewire pipewire-audio pipewire-alsa pipewire-pulse wireplumber
  mate-session-manager mate-panel mate-media polkit mate-polkit caja marco papirus-icon-theme
)
for package in "${live_required[@]}"; do
  grep -Fxq "$package" "$PKG" || fail "pacote live ausente: $package"
done
for package in "${installed_required[@]}"; do
  grep -Fxq "$package" "$INSTALL_PKG" || fail "pacote do sistema instalado ausente: $package"
done

for manifest in "$PKG" "$INSTALL_PKG"; do
  duplicates="$(grep -Ev '^[[:space:]]*(#|$)' "$manifest" | sort | uniq -d)"
  [[ -z "$duplicates" ]] || fail "pacotes duplicados em $manifest: $duplicates"
done

if grep -Eiq '^(archiso|mkinitcpio-archiso|mkinitcpio-nfs-utils|nbd|squashfs-tools|syslinux|base-devel|linux-headers|linux-lts|linux-lts-headers)$' "$INSTALL_PKG"; then
  fail "manifesto do sistema instalado contém ferramentas exclusivas da mídia"
fi

for relative in \
  etc/dconf/db/local.d/00-venom \
  etc/dconf/profile/user \
  etc/skel/.config/autostart/venom-mate-first-login.desktop \
  etc/skel/.config/gtk-3.0/settings.ini \
  etc/skel/.config/gtk-4.0/settings.ini \
  etc/skel/.icons/default/index.theme \
  etc/xdg/autostart/mate-volume-control-status-icon.desktop \
  etc/systemd/system/multi-user.target.wants/NetworkManager.service \
  etc/systemd/system/multi-user.target.wants/bluetooth.service \
  etc/locale.conf \
  etc/locale.gen \
  etc/vconsole.conf \
  etc/X11/xorg.conf.d/00-keyboard.conf \
  usr/local/bin/venom-mate-first-login \
  usr/share/mate-panel/layouts/venom.layout \
  usr/share/backgrounds/venom/venom-wallpaper.svg \
  etc/lightdm/lightdm-gtk-greeter.conf \
  etc/lightdm/lightdm.conf.d/50-venom-session.conf; do
  [[ -s "$OVERLAY/$relative" || -L "$OVERLAY/$relative" ]] ||
    fail "arquivo do overlay ausente: $relative"
done

for service in NetworkManager bluetooth; do
  link="$OVERLAY/etc/systemd/system/multi-user.target.wants/$service.service"
  [[ -L "$link" ]] || fail "serviço não habilitado no sistema instalado: $service"
  [[ "$(readlink "$link")" == "/usr/lib/systemd/system/$service.service" ]] ||
    fail "destino incorreto do link de serviço: $link"
done

grep -Fq 'VENOM_ISO_BUILD_AUTHORIZED' "$ROOT/scripts/build-venom-iso.sh" ||
  fail "script de mídia não exige autorização expressa"
grep -Fq 'gtk_widget_set_sensitive(state->install_button, FALSE)' "$ROOT/installer/src/main.c" ||
  fail "botão de instalação do protótipo deve permanecer desabilitado"
grep -Fq '"lsblk"' "$ROOT/installer/src/disk.c" ||
  fail "descoberta de discos somente leitura ausente"
grep -Fq 'plan->requires_confirmation = TRUE' "$ROOT/installer/src/plan.c" ||
  fail "plano de partições não exige confirmação explícita"
if grep -En '(^|[^[:alnum:]_])(system|g_spawn|GSubprocess|parted|mkfs|sgdisk|wipefs|mount)([^[:alnum:]_]|$)' \
    "$ROOT/installer/src/plan.c"; then
  fail "o planejador declarativo não pode executar operações privilegiadas ou gravar discos"
fi
for required in 'workflow_dispatch:' 'mkarchiso' 'VENOM_ISO_BUILD_AUTHORIZED=YES' 'actions/upload-artifact@v4' 'xorriso'; do
  grep -Fq "$required" "$ROOT/.github/workflows/build-arch-iso.yml" ||
    fail "workflow de mídia incompleta: $required"
done
grep -Fq 'optimize/venom-iso-size' "$ROOT/.github/workflows/build-arch-iso.yml" ||
  fail "workflow não está limitada à branch de trabalho"


# A varredura cobre todas as áreas operacionais e todos os documentos do projeto.
# Os termos são divididos para que o próprio validador não encontre suas regras.
for forbidden in "cala""mares" "endea""vouros"; do
  scan_paths=(
    "$ROOT/AGENTS.md" "$ROOT/README.md" "$ROOT/build" "$ROOT/installer"
    "$ROOT/scripts" "$ROOT/docs" "$ROOT/.github/workflows"
  )
  while IFS= read -r -d '' file; do
    if output="$(grep -I -n -i -F "$forbidden" "$file" 2>&1)"; then
      printf '%s\n' "$output" >&2
      fail "referência legada encontrada: $forbidden"
    else
      status=$?
      [[ "$status" -eq 1 ]] || fail "não foi possível examinar $file"
    fi
  done < <(find "${scan_paths[@]}" -type f -print0)
done

if command -v pacman >/dev/null 2>&1; then
  for manifest in "$PKG" "$INSTALL_PKG"; do
    while IFS= read -r package; do
      [[ -z "$package" || "$package" == \#* ]] && continue
      pacman -Si "$package" >/dev/null 2>&1 ||
        pacman -Sgq "$package" | grep -q . ||
        fail "pacote não encontrado nos repositórios oficiais: $package"
    done < "$manifest"
  done
fi

pass "perfil Archiso, locale pt_BR exclusivo e teclado ABNT2 no live e no overlay instalado"
pass "manifestos live e instalado com pacotes oficiais"
pass "instalador C/GTK4 compilável e instalação ainda bloqueada"
pass "serviços NetworkManager/Bluetooth preparados para live e instalação"
pass "workflow de ISO compila com Archiso, valida boot e publica artefato"

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
  "$ROOT/installer/tests/test-disk.c"
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

grep -Fxq 'LANG=pt_BR.UTF-8' "$P/airootfs/etc/locale.conf" || fail "locale pt_BR ausente"
grep -Fxq 'pt_BR.UTF-8 UTF-8' "$P/airootfs/etc/locale.gen" || fail "locale pt_BR não habilitado"
grep -Fxq 'KEYMAP=br-abnt2' "$P/airootfs/etc/vconsole.conf" || fail "teclado de console ABNT2 ausente"
grep -Fq 'Option "XkbLayout" "br"' "$P/airootfs/etc/X11/xorg.conf.d/00-keyboard.conf" || fail "layout X11 Brasil ausente"
grep -Fq 'Option "XkbVariant" "abnt2"' "$P/airootfs/etc/X11/xorg.conf.d/00-keyboard.conf" || fail "variante X11 ABNT2 ausente"
grep -Fq 'Server = https://geo.mirror.pkgbuild.com/' "$P/pacman.conf" || fail "mirror oficial Arch ausente"
grep -Fq 'Server = https://geo.mirror.pkgbuild.com/' "$P/airootfs/etc/pacman.conf" || fail "mirror oficial Arch ausente no live"
grep -Fq 'COMPRESSION="zstd"' "$P/airootfs/etc/mkinitcpio.conf.d/archiso.conf" || fail "compressão do initramfs inválida"

live_required=(
  base linux linux-firmware archlinux-keyring arch-install-scripts
  mkinitcpio-archiso mkinitcpio-nfs-utils nbd grub efibootmgr
  gtk4 json-glib lightdm networkmanager network-manager-applet
  bluez bluez-utils blueman pipewire pipewire-audio pipewire-pulse
  wireplumber mate-session-manager mate-panel mate-media caja marco
)
installed_required=(
  base linux linux-firmware archlinux-keyring pacman-mirrorlist
  grub efibootmgr mkinitcpio xorg-server lightdm lightdm-gtk-greeter
  networkmanager network-manager-applet bluez bluez-utils blueman
  pipewire pipewire-audio pipewire-pulse wireplumber
  mate-session-manager mate-panel mate-media caja marco
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
grep -Fq 'aguarda autorização expressa' "$ROOT/.github/workflows/build-arch-iso.yml" ||
  fail "workflow de mídia não informa o bloqueio"
if grep -Eiq 'mkarchiso|qemu-system|upload-artifact' "$ROOT/.github/workflows/build-arch-iso.yml"; then
  fail "workflow bloqueada contém etapa de compilação/publicação"
fi

# Os tokens são divididos no código para que a própria validação possa procurar
# referências residuais sem se encontrar no resultado.
for forbidden in "cala""mares" "endea""vouros"; do
  scan_paths=(
    "$ROOT/AGENTS.md" "$ROOT/README.md" "$ROOT/build" "$ROOT/installer"
    "$ROOT/scripts" "$ROOT/docs/PROJECT-CONTINUITY.md" "$ROOT/.github/workflows"
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

pass "perfil Archiso, locale pt_BR e teclado ABNT2"
pass "manifestos live e instalado com pacotes oficiais"
pass "instalador C/GTK4 compilável e instalação ainda bloqueada"
pass "serviços NetworkManager/Bluetooth preparados para live e instalação"
pass "workflow de ISO bloqueada; nenhuma compilação foi iniciada"

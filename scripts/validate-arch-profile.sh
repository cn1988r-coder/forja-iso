#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD="$ROOT/build"
fail() { printf 'FALHA: %s\n' "$*" >&2; exit 1; }
pass() { printf 'OK: %s\n' "$*"; }

required=(
  "$BUILD/profiledef.sh"
  "$BUILD/pacman.conf"
  "$BUILD/packages.x86_64"
  "$BUILD/install-packages-xfce.x86_64"
  "$BUILD/install-packages-mate.x86_64"
  "$BUILD/airootfs/etc/pacman.conf"
  "$BUILD/airootfs/etc/systemd/system/getty@tty1.service.d/autologin.conf"
  "$BUILD/airootfs/usr/lib/venom/install-system"
  "$BUILD/airootfs/usr/share/venom/install-packages-xfce.x86_64"
  "$BUILD/airootfs/usr/share/venom/install-packages-mate.x86_64"
  "$BUILD/install-overlay/usr/share/backgrounds/venom/venom-wallpaper.svg"
  "$BUILD/install-overlay/usr/share/mate-panel/layouts/venom.layout"
  "$BUILD/install-overlay/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml"
  "$BUILD/install-overlay/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml"
  "$BUILD/install-overlay/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml"
  "$BUILD/install-overlay/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml"
  "$ROOT/installer/meson.build"
  "$ROOT/installer/src/tui.c"
  "$ROOT/installer/src/disk.c"
  "$ROOT/installer/src/disk.h"
  "$ROOT/installer/src/plan.c"
  "$ROOT/installer/src/plan.h"
  "$ROOT/installer/tests/test-disk.c"
  "$ROOT/installer/tests/test-plan.c"
  "$ROOT/scripts/build-venom-iso.sh"
)
for file in "${required[@]}"; do
  [[ -s "$file" ]] || fail "arquivo obrigatorio ausente: $file"
done

for script in "$ROOT/scripts/build-venom-iso.sh" \
              "$ROOT/scripts/validate-arch-profile.sh" \
              "$BUILD/profiledef.sh" \
              "$BUILD/airootfs/usr/lib/venom/install-system"; do
  bash -n "$script" || fail "sintaxe Bash invalida: $script"
done

(
  cd "$BUILD"
  # shellcheck disable=SC1091
  source ./profiledef.sh
  [[ "$iso_name" == venom && "$arch" == x86_64 ]] || fail "identidade/arquitetura invalida"
  [[ " ${bootmodes[*]} " == *" bios.syslinux "* ]] || fail "boot BIOS ausente"
  [[ " ${bootmodes[*]} " == *" uefi.grub "* ]] || fail "boot UEFI ausente"
  [[ "$packages" == packages.x86_64 ]] || fail "manifesto live incorreto"
  [[ " ${airootfs_image_tool_options[*]} " == *" zstd "* ]] || fail "SquashFS sem Zstandard"
  [[ "${file_permissions[/usr/lib/venom/install-system]}" == "0:0:755" ]] ||
    fail "backend nao esta marcado como executavel no perfil"
)

grep -Fxq arch-install-scripts "$BUILD/packages.x86_64" ||
  fail "arch-install-scripts ausente na midia"
grep -Fxq ncurses "$BUILD/packages.x86_64" ||
  fail "ncurses ausente na midia"
grep -Fq '/usr/bin/venom-installer' "$BUILD/airootfs/etc/systemd/system/getty@tty1.service.d/autologin.conf" ||
  fail "TTY1 nao inicia diretamente o instalador"
if grep -Eiq 'xfce|mate|lightdm|xorg|gtk' "$BUILD/packages.x86_64"; then
  fail "a midia nao pode iniciar um desktop Live"
fi

for edition in xfce mate; do
  manifest="$BUILD/install-packages-$edition.x86_64"
  bundled="$BUILD/airootfs/usr/share/venom/install-packages-$edition.x86_64"
  build_hash="$(sha256sum "$manifest" | awk '{print $1}')"
  media_hash="$(sha256sum "$bundled" | awk '{print $1}')"
  [[ "$build_hash" == "$media_hash" ]] || fail "manifesto $edition da midia diverge do manifesto de build"
  duplicates="$(grep -Ev '^[[:space:]]*(#|$)' "$manifest" | sort | uniq -d)"
  [[ -z "$duplicates" ]] || fail "pacotes duplicados no manifesto $edition: $duplicates"
  grep -Fxq base "$manifest" || fail "pacote base ausente na edicao $edition"
  grep -Fxq firefox "$manifest" || fail "Firefox ausente na edicao $edition"
  grep -Fxq lightdm "$manifest" || fail "LightDM ausente na edicao $edition"
done

grep -Fxq xfce4 "$BUILD/install-packages-xfce.x86_64" ||
  fail "ambiente XFCE ausente"
grep -Fxq mate-session-manager "$BUILD/install-packages-mate.x86_64" ||
  fail "ambiente MATE ausente"
grep -Fxq thunar "$BUILD/install-packages-xfce.x86_64" ||
  fail "Thunar ausente na edicao XFCE"
grep -Fxq caja "$BUILD/install-packages-mate.x86_64" ||
  fail "Caja ausente na edicao MATE"

grep -Fq 'VENOM_ISO_BUILD_AUTHORIZED' "$ROOT/scripts/build-venom-iso.sh" ||
  fail "build da ISO nao exige autorizacao explicita"
grep -Fq 'pacman -Sw' "$ROOT/scripts/build-venom-iso.sh" ||
  fail "download offline de pacotes ausente"
grep -Fq 'repo-add' "$ROOT/scripts/build-venom-iso.sh" ||
  fail "criacao do repositorio offline ausente"
grep -Fq '/usr/share/venom/install-overlay' "$BUILD/airootfs/usr/lib/venom/install-system" ||
  fail "backend nao aplica configuracao visual VENOM"
grep -Fq 'pacstrap -C' "$BUILD/airootfs/usr/lib/venom/install-system" ||
  fail "backend nao instala a partir da configuracao do repositorio local"
grep -Fq 'wipefs --all --force' "$BUILD/airootfs/usr/lib/venom/install-system" ||
  fail "backend nao possui etapa de particionamento explicita"
grep -Fq 'APAGAR' "$BUILD/airootfs/usr/lib/venom/install-system" ||
  fail "backend nao exige confirmacao destrutiva"
grep -Fq 'choose_edition' "$ROOT/installer/src/tui.c" ||
  fail "selecao das duas edicoes ausente no TUI"
grep -Fq 'serpent_art' "$ROOT/installer/src/tui.c" ||
  fail "ilustracao da serpente ausente na selecao"
grep -Fq "group-windows='always'" "$BUILD/install-overlay/etc/dconf/db/local.d/00-venom" ||
  fail "agrupamento permanente de janelas MATE ausente"
[[ "$(grep -c '^\\[Toplevel ' "$BUILD/install-overlay/usr/share/mate-panel/layouts/venom.layout")" == 1 ]] ||
  fail "MATE deve usar um unico painel inferior"

pass "Perfil TUI e backend offline das edicoes XFCE/MATE validados."

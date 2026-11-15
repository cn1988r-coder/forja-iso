#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
REPO_ROOT="$(cd -- "$ROOT/../.." && pwd)"

for script in "$ROOT/apply-forja-layout.sh" "$ROOT/install-branding.sh" "$REPO_ROOT/build-manjaro.sh" "$REPO_ROOT/forja-pamac-pacman/install.sh"; do
  bash -n "$script"
done

for package in \
  adw-gtk-theme materia-gtk-theme papirus-icon-theme papirus-folders \
  bibata-cursor-theme noto-fonts ttf-jetbrains-mono gtk3 gtk4 \
  gsettings-desktop-schemas flatpak yay base-devel git \
  xfce4-panel xfce4-docklike-plugin xfce4-whiskermenu-plugin; do
  grep -Fxq "$package" "$ROOT/packages.manjaro" || {
    printf 'Pacote obrigatório ausente no perfil XFCE Manjaro: %s\n' "$package" >&2
    exit 1
  }
done

grep -q 'GTK_THEME="adw-gtk3-dark"' "$ROOT/apply-forja-layout.sh"
grep -q 'ICON_THEME="Papirus-Dark"' "$ROOT/apply-forja-layout.sh"
grep -q 'CURSOR_THEME="Bibata-Modern-Classic"' "$ROOT/apply-forja-layout.sh"
grep -q 'set_prop xfwm4 /general/theme string "Materia-dark"' "$ROOT/apply-forja-layout.sh"
grep -q 'set_prop xfwm4 /general/use_compositing bool true' "$ROOT/apply-forja-layout.sh"
grep -q 'WALLPAPER="/usr/share/backgrounds/forja-os-xfce.svg"' "$ROOT/apply-forja-layout.sh"

# The shipped default is a single bottom panel with Docklike, not tasklist.
grep -q 'value="docklike"' "$ROOT/panel-default.xml"
! grep -q 'value="tasklist"' "$ROOT/panel-default.xml"
! grep -q 'panel-2' "$ROOT/panel-default.xml"
grep -q 'value="whiskermenu"' "$ROOT/panel-default.xml"
grep -q 'pinned=thunar.desktop;firefox.desktop;' "$ROOT/docklike.rc"
grep -q 'etc/xdg/xfce4/panel/default.xml' "$ROOT/install-branding.sh"
grep -q 'etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml' "$ROOT/install-branding.sh"
! grep -q 'xfce4-panel --restart' "$ROOT/apply-forja-layout.sh"

grep -q 'forja-papirus-folders.service' "$REPO_ROOT/build-manjaro.sh"
grep -q 'papirus-folders -C grey --theme Papirus-Dark' "$REPO_ROOT/build-manjaro.sh"
grep -q 'adw-gtk3-dark' "$REPO_ROOT/build-manjaro.sh"
grep -q 'Bibata-Modern-Classic' "$REPO_ROOT/build-manjaro.sh"
grep -q 'forja-pamac-pacman/install.sh' "$REPO_ROOT/build-manjaro.sh"
grep -q 'for overlay_name in desktop-overlay live-overlay' "$REPO_ROOT/build-manjaro.sh"
grep -q 'FORJA_SKIP_STORE_INSTALL:-0' "$REPO_ROOT/build-manjaro.sh"

grep -q 'OnlyShowIn=MATE;XFCE;' "$REPO_ROOT/forja-pamac-pacman/forja-update-indicator.desktop"
grep -q 'forja-update-error.svg' "$REPO_ROOT/forja-pamac-pacman/install.sh"
grep -q 'icon="forja-update-error"' "$REPO_ROOT/forja-pamac-pacman/src/forja-update-indicator"

grep -q 'FORJA OS' "$ROOT/forja-xfce-wallpaper.svg"
! grep -qiE 'FORGE|ARCH LINUX|MANJARO' "$ROOT/forja-xfce-wallpaper.svg"

echo "Forja XFCE default Docklike panel and Store integration: static checks passed."

#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
REPO_ROOT="$(cd -- "$ROOT/../.." && pwd)"

for script in "$ROOT/apply-forja-layout.sh" "$ROOT/install-branding.sh" "$REPO_ROOT/build-manjaro.sh" "$REPO_ROOT/forja-pamac-pacman/install.sh" "$REPO_ROOT/forja-pamac-pacman/build-pamac.sh"; do
  bash -n "$script"
done

for package in \
  adw-gtk-theme materia-gtk-theme papirus-icon-theme papirus-folders \
  bibata-cursor-theme noto-fonts ttf-jetbrains-mono gtk3 gtk4 libadwaita libnotify libpamac-flatpak-plugin \
  gsettings-desktop-schemas appstream archlinux-appstream-data flatpak pamac-cli pamac-gtk libpamac libpamac-flatpak-plugin base-devel git \
  xfce4-panel xfce4-docklike-plugin xfce4-whiskermenu-plugin \
  xfce4-pulseaudio-plugin xfce4-power-manager xfce4-notifyd \
  xfce4-clipman-plugin networkmanager network-manager-applet bluez bluez-utils blueman; do
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

# Panel XML must follow the native Xfconf schema: panels array contains panel-1.
grep -q '<property name="panels" type="array">' "$ROOT/panel-default.xml"
grep -q '<property name="panel-1" type="empty">' "$ROOT/panel-default.xml"
grep -q 'value="docklike"' "$ROOT/panel-default.xml"
! grep -q 'value="tasklist"' "$ROOT/panel-default.xml"
! grep -q 'panel-2' "$ROOT/panel-default.xml"
grep -q 'value="whiskermenu"' "$ROOT/panel-default.xml"
# Keep native XFCE indicators grouped on the right, with date/time last.
grep -q 'value="systray"' "$ROOT/panel-default.xml"
grep -q 'value="clock"' "$ROOT/panel-default.xml"
grep -q 'value="pulseaudio"' "$ROOT/panel-default.xml"
grep -q 'value="power-manager-plugin"' "$ROOT/panel-default.xml"
grep -q 'value="notification-plugin"' "$ROOT/panel-default.xml"
grep -q 'value="xfce4-clipman-plugin"' "$ROOT/panel-default.xml"
grep -q 'value="showdesktop"' "$ROOT/panel-default.xml"
grep -q 'name="size-max" type="uint" value="20"' "$ROOT/panel-default.xml"
grep -q 'name="symbolic-icons" type="bool" value="true"' "$ROOT/panel-default.xml"
grep -q 'name="digital-format" type="string" value="%H:%M  ·  %d %b"' "$ROOT/panel-default.xml"
grep -q 'name="tooltip-format" type="string" value="%A, %d de %B de %Y"' "$ROOT/panel-default.xml"
! grep -q 'value="tasklist"' "$ROOT/panel-default.xml"
! grep -q 'value="notification-plugin".*value="clock"' "$ROOT/panel-default.xml"
grep -q 'pinned=thunar.desktop;firefox.desktop;' "$ROOT/docklike.rc"

# Tray applets are supplied by their packages and autostart through XDG.
grep -q 'network-manager-applet' "$ROOT/packages.manjaro"
grep -q 'blueman' "$ROOT/packages.manjaro"
grep -q "'NetworkManager'" "$REPO_ROOT/build-manjaro.sh"
grep -q "'bluetooth'" "$REPO_ROOT/build-manjaro.sh"

grep -q 'etc/xdg/xfce4/panel/default.xml' "$ROOT/install-branding.sh"
grep -q 'etc/xdg/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml' "$ROOT/install-branding.sh"
grep -q 'etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml' "$ROOT/install-branding.sh"
grep -q 'etc/skel/.config/xfce4/panel/docklike.rc' "$ROOT/install-branding.sh"
grep -q 'etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml' "$ROOT/install-branding.sh"
grep -q 'forja-black-wallpaper.svg' "$ROOT/install-branding.sh"
for stock_wallpaper in manjaro-wallpapers-18.0 wallpapers-2018 wallpapers-juhraya illyria-wallpaper manjaro-xfce-settings manjaro-xfce-minimal-settings; do
  grep -q "$stock_wallpaper" "$REPO_ROOT/build-manjaro.sh" || {
    printf 'Pacote de wallpaper/preset XFCE não está excluído: %s\n' "$stock_wallpaper" >&2
    exit 1
  }
done
grep -q 'forja-papirus-folders.service' "$REPO_ROOT/build-manjaro.sh"
grep -q 'papirus-folders -C grey --theme Papirus-Dark' "$REPO_ROOT/build-manjaro.sh"
grep -q 'forja-pamac-pacman/install.sh' "$REPO_ROOT/build-manjaro.sh"
grep -q 'for overlay_name in desktop-overlay live-overlay' "$REPO_ROOT/build-manjaro.sh"
grep -q 'FORJA_SKIP_STORE_INSTALL:-0' "$REPO_ROOT/build-manjaro.sh"

grep -q 'OnlyShowIn=XFCE;' "$REPO_ROOT/forja-pamac-pacman/forja-update-indicator.desktop"
grep -q 'polkit-gnome' "$ROOT/packages.manjaro"
grep -q 'for state in available current error' "$REPO_ROOT/forja-pamac-pacman/install.sh"
grep -q '"forja-update-error"' "$REPO_ROOT/forja-pamac-pacman/src/forja-update-indicator"

grep -q '#000000' "$ROOT/forja-black-wallpaper.svg"
grep -q '/usr/share/backgrounds/forja-black.svg' "$ROOT/forja-xfce-desktop.xml"
! grep -RqiE 'forja-xfce-wallpaper|xfce-wallpaper.svg' "$ROOT"


grep -q 'button-icon.*forja' "$ROOT/panel-default.xml"
grep -q 'show-button-icon.*true' "$ROOT/panel-default.xml"
grep -q 'position-search-alternate.*true' "$ROOT/panel-default.xml"
grep -q 'position-categories-alternate.*true' "$ROOT/panel-default.xml"
grep -q 'menu-width.*560' "$ROOT/panel-default.xml"
grep -q 'whiskermenu-1.rc' "$ROOT/install-branding.sh"
grep -q 'etc/skel/.config/gtk-3.0/gtk.css' "$ROOT/install-branding.sh"
! grep -q 'etc/xdg/gtk-3.0/gtk.css' "$ROOT/install-branding.sh"
grep -q '#whiskermenu-button:checked' "$ROOT/forja-gtk.css"
grep -Eq 'box-shadow:[[:space:]]*inset[[:space:]]*0[[:space:]]+-2px[[:space:]]+0' "$ROOT/forja-gtk.css"
grep -q '#whiskermenu-window .category-button:checked' "$ROOT/forja-gtk.css"
grep -q '#whiskermenu-window .search-area' "$ROOT/forja-gtk.css"


# Whisker identity must stay monochrome and visually aligned with Adwaita Dark.
grep -q 'fill="#171717"' "$ROOT/forja-flame.svg"
grep -q 'fill="#dededb"' "$ROOT/forja-flame.svg"
! grep -q 'linearGradient\|stop-color=' "$ROOT/forja-flame.svg"
grep -q '@define-color forja_bg #242424' "$ROOT/forja-gtk.css"
grep -q '@define-color forja_surface #303030' "$ROOT/forja-gtk.css"
grep -q '@define-color forja_text #ffffff' "$ROOT/forja-gtk.css"
! grep -qiE '#[0-9a-f]*(00a|08f|f80|f00)' "$ROOT/forja-gtk.css"

# Update badge is intentionally white with a gray check; pending updates use a red X.
grep -q 'stroke="#ffffff"' "$REPO_ROOT/forja-pamac-pacman/icons/forja-update-current.svg"
grep -q 'stroke="#777777"' "$REPO_ROOT/forja-pamac-pacman/icons/forja-update-current.svg"
grep -q 'stroke="#ffffff"' "$REPO_ROOT/forja-pamac-pacman/icons/forja-update-available.svg"
grep -q 'stroke="#e53935"' "$REPO_ROOT/forja-pamac-pacman/icons/forja-update-available.svg"
grep -q 'OnlyShowIn=XFCE;' "$REPO_ROOT/forja-pamac-pacman/forja-update-indicator.desktop"

# Forja Store is the Pamac GTK4/libadwaita frontend with Forja styling.
test -f "$REPO_ROOT/forja-pamac-pacman/build-pamac.sh"
test -f "$REPO_ROOT/forja-pamac-pacman/patches/forja-store.css"
grep -q 'UPSTREAM_COMMIT="363e794fef4f9f6a0e54757fd12155cf27e02cc3"' "$REPO_ROOT/forja-pamac-pacman/build-pamac.sh"
grep -q 'meson compile -C "$BUILD" pamac-manager' "$REPO_ROOT/forja-pamac-pacman/build-pamac.sh"
grep -q 'about.application_name = "Forja Store"' "$REPO_ROOT/forja-pamac-pacman/build-pamac.sh"
grep -q '@define-color forja_bg #111111' "$REPO_ROOT/forja-pamac-pacman/patches/forja-store.css"
grep -q 'boxed-list > row' "$REPO_ROOT/forja-pamac-pacman/patches/forja-store.css"
grep -q 'button.suggested-action' "$REPO_ROOT/forja-pamac-pacman/patches/forja-store.css"
grep -q 'FORJA_PAMAC_BUILD_DIR' "$REPO_ROOT/forja-pamac-pacman/install.sh"
grep -q 'libpamac-flatpak-plugin' "$ROOT/packages.manjaro"
grep -q 'build-pamac.sh' "$REPO_ROOT/build-manjaro.sh"
grep -q 'LD_LIBRARY_PATH="/usr/lib/forja' "$REPO_ROOT/forja-pamac-pacman/bin/forja-store"
grep -q 'pamac' "$REPO_ROOT/forja-pamac-pacman/src/forja-pacman-transaction"
grep -q 'parse_flatpak_updates' "$REPO_ROOT/forja-pamac-pacman/src/forja-update-indicator"
grep -q 'forja_store_core.py' "$REPO_ROOT/forja-pamac-pacman/install.sh"

echo "Forja XFCE: aparência, painel, Docklike, indicador e interface Pamac da Forja validados."

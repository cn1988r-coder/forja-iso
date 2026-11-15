#!/usr/bin/env bash
set -Eeuo pipefail
[[ "$EUID" -eq 0 ]] || { echo "Execute como root." >&2; exit 1; }
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
DEST="${DESTDIR:-}"

install -Dm644 "$ROOT/forja-flame.svg" "$DEST/usr/share/icons/hicolor/scalable/apps/forja.svg"
install -Dm644 "$ROOT/forja-black-wallpaper.svg" "$DEST/usr/share/backgrounds/forja-black.svg"
install -Dm755 "$ROOT/apply-forja-layout.sh" "$DEST/usr/lib/forja/apply-xfce-layout.sh"
install -Dm644 "$ROOT/forja-xfce-appearance.desktop" "$DEST/etc/xdg/autostart/forja-xfce-appearance.desktop"
install -Dm644 "$ROOT/forja-gtk.css" "$DEST/etc/skel/.config/gtk-3.0/gtk.css"
install -Dm644 "$ROOT/forja-whiskermenu.rc" "$DEST/etc/skel/.config/xfce4/panel/whiskermenu-1.rc"

# A single system-wide panel: Whisker + Docklike + system tray + clock.
install -Dm644 "$ROOT/panel-default.xml" "$DEST/etc/xdg/xfce4/panel/default.xml"
install -Dm644 "$ROOT/docklike.rc" "$DEST/etc/skel/.config/xfce4/panel/docklike.rc"
install -Dm644 "$ROOT/docklike.rc" "$DEST/etc/xdg/xfce4/panel/docklike.rc"
install -Dm644 "$ROOT/forja-xfce-desktop.xml" "$DEST/etc/xdg/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml"

# Seed the same defaults for the Manjaro Live account and newly created users.
install -Dm644 "$ROOT/panel-default.xml" \
  "$DEST/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml"
install -Dm644 "$ROOT/forja-xfce-desktop.xml" \
  "$DEST/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml"

if [[ -z "$DEST" ]] && command -v gtk-update-icon-cache >/dev/null 2>&1; then
  gtk-update-icon-cache -q -f /usr/share/icons/hicolor || true
fi
echo "Forja OS XFCE: Whisker Menu escuro e identificado, Docklike, bandeja, relógio e fundo preto configurados."

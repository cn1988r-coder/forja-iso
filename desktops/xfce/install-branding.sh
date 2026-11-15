#!/usr/bin/env bash
set -Eeuo pipefail
[[ "$EUID" -eq 0 ]] || { echo "Execute como root." >&2; exit 1; }
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
DEST="${DESTDIR:-}"

install -Dm644 "$ROOT/forja-flame.svg" "$DEST/usr/share/icons/hicolor/scalable/apps/forja.svg"
install -Dm755 "$ROOT/apply-forja-layout.sh" "$DEST/usr/lib/forja/apply-xfce-layout.sh"
install -Dm644 "$ROOT/forja-xfce-appearance.desktop" "$DEST/etc/xdg/autostart/forja-xfce-appearance.desktop"
install -Dm644 "$ROOT/forja-gtk.css" "$DEST/etc/xdg/gtk-3.0/gtk.css"

# Replace the upstream XFCE panel defaults with one Forja panel. Docklike is
# the taskbar; the stock tasklist and the second/legacy panel are not included.
install -Dm644 "$ROOT/panel-default.xml" "$DEST/etc/xdg/xfce4/panel/default.xml"
install -Dm644 "$ROOT/docklike.rc" "$DEST/etc/xdg/xfce4/panel/docklike.rc"

# Seed the same panel channel for the Live user and every newly created user.
install -Dm644 "$ROOT/panel-default.xml" \
  "$DEST/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml"

if [[ -z "$DEST" ]] && command -v gtk-update-icon-cache >/dev/null 2>&1; then
  gtk-update-icon-cache -q -f /usr/share/icons/hicolor || true
fi
echo "Forja OS XFCE: painel padrão substituído por Whisker + Docklike."

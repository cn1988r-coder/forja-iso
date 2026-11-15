#!/usr/bin/env bash
set -Eeuo pipefail
[[ "$EUID" -eq 0 ]] || { echo "Execute como root." >&2; exit 1; }
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
DEST="${DESTDIR:-}"
install -Dm644 "$ROOT/forja-flame.svg" "$DEST/usr/share/icons/hicolor/scalable/apps/forja.svg"
install -Dm755 "$ROOT/apply-forja-layout.sh" "$DEST/usr/lib/forja/apply-xfce-layout.sh"
install -Dm644 "$ROOT/forja-xfce-appearance.desktop" "$DEST/etc/xdg/autostart/forja-xfce-appearance.desktop"
install -Dm644 "$ROOT/forja-gtk.css" "$DEST/etc/xdg/gtk-3.0/gtk.css"
if [[ -z "$DEST" ]] && command -v gtk-update-icon-cache >/dev/null 2>&1; then
  gtk-update-icon-cache -q -f /usr/share/icons/hicolor || true
fi
echo "Forja OS XFCE: identidade escura, Whisker e Docklike instalados."

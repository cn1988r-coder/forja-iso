#!/usr/bin/env bash
set -Eeuo pipefail
[[ $EUID -eq 0 ]] || { echo "Execute como root."; exit 1; }
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
DESTDIR="${DESTDIR:-}"
target() { printf "%s%s" "$DESTDIR" "$1"; }
. /etc/os-release
[[ "${ID:-}" == manjaro ]] || {
  echo "Forja Software Pacman é exclusivo da base Manjaro."
  exit 1
}
ICON="$ROOT/icons/forja-store.svg"
install -d "$(target /usr/lib/forja)" "$(target /usr/bin)" \
  "$(target /usr/share/icons/hicolor/scalable/apps)" \
  "$(target /usr/share/icons/hicolor/scalable/status)" \
  "$(target /etc/xdg/autostart)" "$(target /usr/share/applications)"
install -m 755 "$ROOT/src/forja-store" "$(target /usr/lib/forja/forja-store)"
install -m 755 "$ROOT/src/forja-update-indicator" "$(target /usr/lib/forja/forja-update-indicator)"
install -m 755 "$ROOT/src/forja-pacman-transaction" "$(target /usr/lib/forja/forja-pacman-transaction)"
install -m 755 "$ROOT/bin/forja-store" "$(target /usr/bin/forja-store)"
install -m 755 "$ROOT/bin/forja-update-indicator" "$(target /usr/bin/forja-update-indicator)"
install -m 644 "$ICON" "$(target "/usr/share/icons/hicolor/scalable/apps/$(basename "$ICON")")"
install -m 644 "$ROOT/icons/forja-update-available.svg" "$(target /usr/share/icons/hicolor/scalable/status/forja-update-available.svg)"
install -m 644 "$ROOT/icons/forja-update-current.svg" "$(target /usr/share/icons/hicolor/scalable/status/forja-update-current.svg)"
install -m 644 "$ROOT/forja-update-indicator.desktop" "$(target /etc/xdg/autostart/forja-update-indicator.desktop)"
install -m 644 "$ROOT/forja-software.desktop" "$(target /usr/share/applications/forja-software.desktop)"
if [[ -z "$DESTDIR" ]]; then gtk-update-icon-cache -f /usr/share/icons/hicolor 2>/dev/null || true; fi
echo "Forja Store e indicador de atualizações instalados."

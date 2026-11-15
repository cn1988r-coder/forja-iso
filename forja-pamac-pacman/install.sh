#!/usr/bin/env bash
set -Eeuo pipefail
[[ $EUID -eq 0 ]] || { echo "Execute como root."; exit 1; }
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
. /etc/os-release
case "${ID:-arch}" in
  manjaro) ICON="$ROOT/icons/forja-pamac-manjaro.svg" ;;
  arch) ICON="$ROOT/icons/forja-pamac-arch.svg" ;;
  *) echo "Esta instalação suporta somente Arch Linux e Manjaro."; exit 1 ;;
esac
install -d /usr/lib/forja /usr/bin /usr/share/icons/hicolor/scalable/apps /etc/xdg/autostart
install -m 755 "$ROOT/src/forja-store" /usr/lib/forja/forja-store
install -m 755 "$ROOT/src/forja-update-indicator" /usr/lib/forja/forja-update-indicator
install -m 755 "$ROOT/src/forja-pacman-transaction" /usr/lib/forja/forja-pacman-transaction
install -m 755 "$ROOT/bin/forja-store" /usr/bin/forja-store
install -m 755 "$ROOT/bin/forja-update-indicator" /usr/bin/forja-update-indicator
install -m 644 "$ICON" "/usr/share/icons/hicolor/scalable/apps/$(basename "$ICON")"
install -m 644 "$ROOT/forja-update-indicator.desktop" /etc/xdg/autostart/forja-update-indicator.desktop
gtk-update-icon-cache -f /usr/share/icons/hicolor 2>/dev/null || true
echo "Forja Software instalado. Encerre e inicie a sessão para ativar o indicador."

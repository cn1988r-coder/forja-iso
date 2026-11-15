#!/usr/bin/env bash
set -Eeuo pipefail

# Executar como root durante a composição da imagem Arch XFCE.
[[ "$EUID" -eq 0 ]] || { echo "Execute como root." >&2; exit 1; }
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

install -Dm644 "$ROOT/forja-flame.svg" /usr/share/icons/hicolor/scalable/apps/forja.svg
install -Dm755 "$ROOT/apply-mint-layout.sh" /usr/lib/forja/apply-xfce-mint-layout.sh
install -Dm644 "$ROOT/forja-xfce-mint-layout.desktop" /etc/xdg/autostart/forja-xfce-appearance.desktop

if command -v gtk-update-icon-cache >/dev/null 2>&1; then
  gtk-update-icon-cache -q -f /usr/share/icons/hicolor || true
fi

echo "Identidade visual Forja instalada: ícone Whisker e configuração XFCE. Mantido o wallpaper padrão do XFCE."

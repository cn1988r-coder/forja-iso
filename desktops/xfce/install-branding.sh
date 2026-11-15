#!/usr/bin/env bash
set -Eeuo pipefail

# Instala a identidade visual Forja no sistema de arquivos da imagem.
# Executar como root durante a composição da ISO Arch XFCE.
[[ "$EUID" -eq 0 ]] || { echo "Execute como root." >&2; exit 1; }

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
install -Dm644 "$ROOT/forja-flame.svg" /usr/share/icons/hicolor/scalable/apps/forja.svg
install -Dm644 "$ROOT/forja-xfce-wallpaper.svg" /usr/share/backgrounds/forja/forja-xfce.svg

if command -v gtk-update-icon-cache >/dev/null 2>&1; then
  gtk-update-icon-cache -q -f /usr/share/icons/hicolor || true
fi

echo "Identidade visual Forja instalada: ícone do menu e wallpaper XFCE."

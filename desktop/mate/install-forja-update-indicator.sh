#!/usr/bin/env bash
set -Eeuo pipefail

# Install the Forja update indicator into an already prepared Arch rootfs.
# Usage: install-forja-update-indicator.sh /path/to/airootfs

ROOT="${1:-}"
if [[ -z "$ROOT" || ! -d "$ROOT" ]]; then
    echo "Uso: $0 /caminho/para/airootfs" >&2
    exit 2
fi

SOURCE_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
install -d "$ROOT/usr/bin" "$ROOT/usr/lib/forja" \
    "$ROOT/usr/share/icons/hicolor/scalable/apps" \
    "$ROOT/etc/xdg/autostart"

install -m 0755 "$SOURCE_DIR/forja-update-indicator/forja-update-indicator.py" \
    "$ROOT/usr/lib/forja/forja-update-indicator"
cat > "$ROOT/usr/bin/forja-update-indicator" <<'LAUNCHER'
#!/usr/bin/env sh
exec /usr/bin/python3 /usr/lib/forja/forja-update-indicator "$@"
LAUNCHER
chmod 0755 "$ROOT/usr/bin/forja-update-indicator"

install -m 0644 "$SOURCE_DIR/forja-update-indicator/icons/forja-update-current.svg" \
    "$ROOT/usr/share/icons/hicolor/scalable/apps/forja-update-current.svg"
install -m 0644 "$SOURCE_DIR/forja-update-indicator/icons/forja-update-available.svg" \
    "$ROOT/usr/share/icons/hicolor/scalable/apps/forja-update-available.svg"
install -m 0644 "$SOURCE_DIR/forja-update-indicator/forja-update-indicator.desktop" \
    "$ROOT/etc/xdg/autostart/forja-update-indicator.desktop"

echo "Indicador da Forja OS instalado em $ROOT."
echo "Dependências: python-gobject e pacman-contrib."

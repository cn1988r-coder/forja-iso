#!/usr/bin/env bash
set -Eeuo pipefail

# Installs the graphical Forja Store into a prepared Arch Linux root filesystem.
ROOT="${1:-}"
if [[ -z "$ROOT" || ! -d "$ROOT" ]]; then
  echo "Uso: $0 /caminho/para/airootfs" >&2
  exit 2
fi

SOURCE="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
install -d "$ROOT/usr/bin" "$ROOT/usr/lib/forja" \
  "$ROOT/usr/share/applications" "$ROOT/usr/share/polkit-1/actions" \
  "$ROOT/usr/share/icons/hicolor/scalable/apps"

# The Python GTK application is installed separately from its executable launcher.
install -m 0755 "$SOURCE/forja-store/forja-store.py" "$ROOT/usr/lib/forja/forja-store"
install -m 0755 "$SOURCE/forja-store/forja-pacman-transaction" \
  "$ROOT/usr/bin/forja-pacman-transaction"
install -m 0755 "$SOURCE/forja-store/forja-aur-build" "$ROOT/usr/bin/forja-aur-build"

cat > "$ROOT/usr/bin/forja-store" <<'LAUNCHER'
#!/usr/bin/env sh
exec /usr/bin/python3 /usr/lib/forja/forja-store "$@"
LAUNCHER
chmod 0755 "$ROOT/usr/bin/forja-store"

install -m 0644 "$SOURCE/forja-store/br.forja.store.policy" \
  "$ROOT/usr/share/polkit-1/actions/br.forja.store.policy"
install -m 0644 "$SOURCE/forja-store/forja-store.desktop" \
  "$ROOT/usr/share/applications/forja-store.desktop"
install -m 0644 "$SOURCE/forja-store/forja-store.svg" \
  "$ROOT/usr/share/icons/hicolor/scalable/apps/forja-store.svg"

# Refresh desktop/icon caches when the utilities are present in the target root.
if command -v gtk-update-icon-cache >/dev/null 2>&1; then
  gtk-update-icon-cache -q -t "$ROOT/usr/share/icons/hicolor" || true
fi
if command -v update-desktop-database >/dev/null 2>&1; then
  update-desktop-database "$ROOT/usr/share/applications" || true
fi

echo "Forja Store gráfica instalada em $ROOT."
echo "Lançador: /usr/bin/forja-store (Terminal=false; ícone forja-store)."

#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="${1:-}"
if [[ -z "$ROOT" || ! -d "$ROOT" ]]; then
  echo "Uso: $0 /caminho/para/airootfs" >&2
  exit 2
fi
SOURCE="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
install -d "$ROOT/usr/bin" "$ROOT/usr/lib/forja" \
  "$ROOT/usr/share/applications" "$ROOT/usr/share/polkit-1/actions" \
  "$ROOT/usr/share/icons/hicolor/scalable/apps" "$ROOT/etc/polkit-1/rules.d" \
  "$ROOT/etc/forja"
install -m 0755 "$SOURCE/forja-store/forja-store.py" "$ROOT/usr/lib/forja/forja-store"
install -m 0755 "$SOURCE/forja-store/forja-pacman-transaction" "$ROOT/usr/bin/forja-pacman-transaction"
install -m 0755 "$SOURCE/forja-store/forja-aur-build" "$ROOT/usr/bin/forja-aur-build"
install -m 0755 "$SOURCE/forja-repo/forja-repo" "$ROOT/usr/bin/forja-repo"
install -m 0644 "$SOURCE/forja-repo/pacman.conf" "$ROOT/etc/forja/pacman.conf"
install -m 0644 "$SOURCE/forja-repo/pacman-install.conf" "$ROOT/etc/forja/pacman-install.conf"
install -d "$ROOT/var/lib/forja-repo" "$ROOT/var/cache/forja-repo/pkg"
cat > "$ROOT/usr/bin/forja-store" <<'LAUNCHER'
#!/usr/bin/env sh
exec /usr/bin/python3 /usr/lib/forja/forja-store "$@"
LAUNCHER
chmod 0755 "$ROOT/usr/bin/forja-store"
install -m 0644 "$SOURCE/forja-store/br.forja.store.policy" "$ROOT/usr/share/polkit-1/actions/br.forja.store.policy"
install -m 0644 "$SOURCE/forja-store/49-forja-store.rules" "$ROOT/etc/polkit-1/rules.d/49-forja-store.rules"
install -m 0644 "$SOURCE/forja-store/forja-store.desktop" "$ROOT/usr/share/applications/forja-store.desktop"
install -m 0644 "$SOURCE/forja-store/forja-store.svg" "$ROOT/usr/share/icons/hicolor/scalable/apps/forja-store.svg"
echo "Forja Store instalada em $ROOT"

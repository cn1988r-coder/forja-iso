#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
DESTDIR="${DESTDIR:-}"

install -Dm755 "$ROOT/forja-luz-noturna.py" "$DESTDIR/usr/bin/forja-luz-noturna"
install -Dm644 "$ROOT/../skel/.config/autostart/forja-luz-noturna.desktop" \
    "$DESTDIR/etc/xdg/autostart/forja-luz-noturna.desktop"

printf 'Forja Luz Noturna instalada em %s/usr/bin/forja-luz-noturna\n' "$DESTDIR"
printf 'Autostart instalado em %s/etc/xdg/autostart/\n' "$DESTDIR"

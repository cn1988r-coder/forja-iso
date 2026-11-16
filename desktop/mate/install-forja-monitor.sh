#!/usr/bin/env bash
set -euo pipefail
ROOT="${1:-}"
[[ -n "$ROOT" && -d "$ROOT" ]] || { echo "Uso: $0 /caminho/para/airootfs" >&2; exit 2; }
HERE="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
install -Dm755 "$HERE/forja-monitor.py" "$ROOT/usr/bin/forja-monitor"
install -Dm644 "$HERE/forja-flame.svg" "$ROOT/usr/share/forja-monitor/forja-flame.svg"
install -Dm644 "$HERE/forja-monitor.desktop" "$ROOT/usr/share/applications/forja-monitor.desktop"
install -Dm755 "$HERE/forja-monitor/record-install-time.py" "$ROOT/usr/bin/forja-record-install-time"

#!/usr/bin/env bash
set -Eeuo pipefail
if [[ "${VENOM_ISO_APPROVED:-}" != "YES" ]]; then
  echo "Compilação bloqueada. Só executar após validação completa e autorização expressa." >&2
  exit 64
fi
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
"$ROOT/scripts/validate-manjaro-build.sh"
cd /usr/share/manjaro-tools/iso-profiles
sudo buildiso -p venom-mate -b stable -k linux618
